begin;
create schema if not exists extensions;
create extension if not exists pgcrypto with schema extensions;
create schema if not exists game_private;
revoke all on schema game_private from public, anon, authenticated;

create table if not exists game_private.accounts (
 id uuid primary key default gen_random_uuid(),
 username text not null unique check(username ~ '^[a-z][a-z0-9_]{2,23}$'),
 password_hash text not null,
 created_at timestamptz not null default now()
);
create table if not exists game_private.sessions (
 token_hash text primary key, account_id uuid not null references game_private.accounts(id) on delete cascade,
 expires_at timestamptz not null, created_at timestamptz not null default now()
);
create index if not exists game_sessions_expiry on game_private.sessions(expires_at);
create index if not exists game_sessions_account on game_private.sessions(account_id);
create table if not exists game_private.saves (
 account_id uuid primary key references game_private.accounts(id) on delete cascade,
 revision bigint not null default 0 check(revision>=0),
 payload jsonb not null default '{"schema":1,"slots":[null,null,null,null,null],"last_slot":0}',
 updated_at timestamptz not null default now(),
 check(octet_length(payload::text)<=2097152)
);
create table if not exists game_private.rate_limits (
 bucket text primary key, started_at timestamptz not null, attempts integer not null
);
create index if not exists game_rate_expiry on game_private.rate_limits(started_at);
create table if not exists game_private.config (id boolean primary key default true check(id),dummy_hash text not null);
insert into game_private.config(id,dummy_hash) values(true,extensions.crypt(encode(extensions.gen_random_bytes(32),'hex'),extensions.gen_salt('bf',10))) on conflict do nothing;
alter table game_private.accounts enable row level security;
alter table game_private.sessions enable row level security;
alter table game_private.saves enable row level security;
alter table game_private.rate_limits enable row level security;
alter table game_private.config enable row level security;
revoke all on all tables in schema game_private from public, anon, authenticated;

create or replace function game_private.allow_attempt(k text, cap integer, seconds integer)
returns boolean language plpgsql set search_path='' as $$
declare n integer; stamp timestamptz:=clock_timestamp();
begin
 insert into game_private.rate_limits(bucket,started_at,attempts) values(k,stamp,1)
 on conflict(bucket) do update set
 attempts=case when game_private.rate_limits.started_at < stamp-make_interval(secs=>seconds) then 1 else game_private.rate_limits.attempts+1 end,
 started_at=case when game_private.rate_limits.started_at < stamp-make_interval(secs=>seconds) then stamp else game_private.rate_limits.started_at end
 returning attempts into n;
 return n<=cap;
end $$;

create or replace function game_private.auth_gate(action text, uname text)
returns boolean language plpgsql set search_path='' as $$
declare headers jsonb; ip text; tag text;
begin
 -- The global budget also bounds callers with forged/missing proxy headers.
 if not game_private.allow_attempt('global:auth',120,60) then return false;end if;
 begin headers:=coalesce(nullif(current_setting('request.headers',true),''),'{}')::jsonb;exception when others then headers:='{}';end;
 ip:=left(coalesce(headers->>'cf-connecting-ip',headers->>'x-real-ip',split_part(headers->>'x-forwarded-for',',',1),'unknown'),128);
 tag:=encode(extensions.digest(ip,'sha256'),'hex');
 if action='register' then
  if not game_private.allow_attempt('global:register',120,3600) then return false;end if;
  if not game_private.allow_attempt('register:ip:'||tag,5,600) then return false;end if;
 else
  if not game_private.allow_attempt('login:ip:'||tag,30,60) then return false;end if;
  if not game_private.allow_attempt('login:user:'||uname,8,60) then return false;end if;
 end if;
 delete from game_private.rate_limits where started_at < now()-interval '2 days';
 return true;
end $$;

create or replace function game_private.issue_session(owner_id uuid)
returns jsonb language plpgsql set search_path='' as $$
declare secret text:=encode(extensions.gen_random_bytes(32),'hex'); expires timestamptz:=now()+interval '24 hours'; name text;
begin
 delete from game_private.sessions where expires_at<=now();
 insert into game_private.sessions(token_hash,account_id,expires_at) values(encode(extensions.digest(secret,'sha256'),'hex'),owner_id,expires);
 delete from game_private.sessions where account_id=owner_id and token_hash not in
 (select token_hash from game_private.sessions where account_id=owner_id order by created_at desc,token_hash limit 16);
 select username into name from game_private.accounts where id=owner_id;
 return jsonb_build_object('ok',true,'session_token',secret,'expires_at',extract(epoch from expires),'user',jsonb_build_object('id',owner_id,'username',name));
end $$;

create or replace function game_private.session_owner(secret text)
returns uuid language sql stable set search_path='' as $$
 select account_id from game_private.sessions
 where length(secret)=64 and token_hash=encode(extensions.digest(secret,'sha256'),'hex') and expires_at>now()
$$;

create or replace function public.game_register(p_username text,p_password text)
returns jsonb language plpgsql security definer set search_path='' as $$
declare uname text:=lower(btrim(p_username)); owner_id uuid;
begin
 if uname is null or uname !~ '^[a-z][a-z0-9_]{2,23}$' then return jsonb_build_object('ok',false,'error','invalid_username');end if;
 if p_password is null or length(p_password)<8 or octet_length(p_password)>72 then return jsonb_build_object('ok',false,'error','invalid_password');end if;
 if not game_private.auth_gate('register',uname) then return jsonb_build_object('ok',false,'error','rate_limited');end if;
 if exists(select 1 from game_private.accounts where username=uname) then return jsonb_build_object('ok',false,'error','username_taken');end if;
 insert into game_private.accounts(username,password_hash) values(uname,extensions.crypt(p_password,extensions.gen_salt('bf',10)))
 on conflict(username) do nothing returning id into owner_id;
 if owner_id is null then return jsonb_build_object('ok',false,'error','username_taken');end if;
 insert into game_private.saves(account_id) values(owner_id);
 return game_private.issue_session(owner_id);
end $$;

create or replace function public.game_sign_in(p_username text,p_password text)
returns jsonb language plpgsql security definer set search_path='' as $$
declare uname text:=lower(btrim(p_username)); who game_private.accounts; dummy text; match boolean;
begin
 if uname is null or uname !~ '^[a-z][a-z0-9_]{2,23}$' or p_password is null or length(p_password)<8 or octet_length(p_password)>72 then
  return jsonb_build_object('ok',false,'error','invalid_credentials');end if;
 if not game_private.auth_gate('login',uname) then return jsonb_build_object('ok',false,'error','rate_limited');end if;
 select * into who from game_private.accounts where username=uname;
 select dummy_hash into dummy from game_private.config where id=true;
 match:=extensions.crypt(p_password,coalesce(who.password_hash,dummy))=coalesce(who.password_hash,dummy);
 -- Return failures rather than raising: attempt counters must remain committed.
 if who.id is null or not match then return jsonb_build_object('ok',false,'error','invalid_credentials');end if;
 return game_private.issue_session(who.id);
end $$;

create or replace function public.game_whoami(p_session_token text)
returns jsonb language plpgsql security definer set search_path='' as $$
declare who uuid:=game_private.session_owner(p_session_token); name text;
begin
 if who is null then return jsonb_build_object('ok',false,'error','session_expired');end if;
 select username into name from game_private.accounts where id=who;
 return jsonb_build_object('ok',true,'user',jsonb_build_object('id',who,'username',name));
end $$;

create or replace function public.game_read_save(p_session_token text)
returns jsonb language plpgsql security definer set search_path='' as $$
declare who uuid:=game_private.session_owner(p_session_token); result jsonb;
begin
 if who is null then return jsonb_build_object('ok',false,'error','session_expired');end if;
 select jsonb_build_object('ok',true,'revision',revision,'payload',payload) into result from game_private.saves where account_id=who;
 return result;
end $$;

create or replace function public.game_write_save(p_session_token text,p_expected_revision bigint,p_payload jsonb)
returns jsonb language plpgsql security definer set search_path='' as $$
declare who uuid:=game_private.session_owner(p_session_token); rev bigint; entry jsonb;
begin
 if who is null then return jsonb_build_object('ok',false,'error','session_expired');end if;
 if p_expected_revision is null or p_expected_revision<0 or p_payload is null or jsonb_typeof(p_payload)<>'object'
 or p_payload->>'schema' is distinct from '1' or jsonb_typeof(p_payload->'slots') is distinct from 'array'
 or jsonb_typeof(p_payload->'last_slot') is distinct from 'number' or octet_length(p_payload::text)>2097152 then
  return jsonb_build_object('ok',false,'error','invalid_save');end if;
 if jsonb_array_length(p_payload->'slots')<>5 or (p_payload->>'last_slot')::numeric not in (0,1,2,3,4) then return jsonb_build_object('ok',false,'error','invalid_save');end if;
 for entry in select value from jsonb_array_elements(p_payload->'slots') loop
  if jsonb_typeof(entry) not in ('null','object') then return jsonb_build_object('ok',false,'error','invalid_save');end if;
  if jsonb_typeof(entry)='object' and (jsonb_typeof(entry->'player_name') is distinct from 'string' or jsonb_typeof(entry->'inventory') is distinct from 'object' or jsonb_typeof(entry->'save_point') is distinct from 'array') then
   return jsonb_build_object('ok',false,'error','invalid_save');end if;
 end loop;
 select revision into rev from game_private.saves where account_id=who for update;
 if rev<>p_expected_revision then return jsonb_build_object('ok',false,'revision',rev,'error','conflict');end if;
 update game_private.saves set payload=p_payload,revision=rev+1,updated_at=now() where account_id=who;
 return jsonb_build_object('ok',true,'revision',rev+1);
end $$;

create or replace function public.game_sign_out(p_session_token text)
returns jsonb language plpgsql security definer set search_path='' as $$
begin
 delete from game_private.sessions where token_hash=encode(extensions.digest(p_session_token,'sha256'),'hex');
 return jsonb_build_object('ok',true);
end $$;

revoke all on all functions in schema game_private from public,anon,authenticated;
revoke all on function public.game_register(text,text),public.game_sign_in(text,text),public.game_whoami(text),public.game_read_save(text),public.game_write_save(text,bigint,jsonb),public.game_sign_out(text) from public,anon,authenticated;
grant execute on function public.game_register(text,text),public.game_sign_in(text,text),public.game_whoami(text),public.game_read_save(text),public.game_write_save(text,bigint,jsonb),public.game_sign_out(text) to anon,authenticated;
commit;
