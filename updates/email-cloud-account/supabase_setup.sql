-- Run once in the SQL Editor of the intended Supabase project.
begin;
create table if not exists public.account_saves (
  user_id uuid primary key references auth.users(id) on delete cascade,
  revision bigint not null default 0 check (revision >= 0),
  payload jsonb not null,
  updated_at timestamptz not null default now(),
  constraint account_save_size check (octet_length(payload::text) <= 2097152)
);
alter table public.account_saves enable row level security;
revoke all on public.account_saves from anon, authenticated;
grant select on public.account_saves to authenticated;
drop policy if exists account_save_owner_read on public.account_saves;
create policy account_save_owner_read on public.account_saves
  for select to authenticated using ((select auth.uid()) = user_id);

-- One atomic compare-and-swap for the complete five-slot account bundle.
-- Clients cannot choose a user_id or bypass revision checks through REST writes.
create or replace function public.save_account(expected_revision bigint, new_payload jsonb)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  owner_id uuid := auth.uid();
  current_revision bigint;
  entry jsonb;
begin
  if owner_id is null or not exists (
    select 1 from auth.users where id = owner_id and email_confirmed_at is not null
  ) then
    raise exception 'Verified email required' using errcode = '42501';
  end if;
  if expected_revision is null or expected_revision < 0
     or new_payload is null or jsonb_typeof(new_payload) <> 'object'
     or new_payload->>'schema' is distinct from '1'
     or jsonb_typeof(new_payload->'slots') is distinct from 'array'
     or jsonb_typeof(new_payload->'last_slot') is distinct from 'number'
     or octet_length(new_payload::text) > 2097152 then
    raise exception 'Invalid save bundle' using errcode = '22023';
  end if;
  if jsonb_array_length(new_payload->'slots') <> 5
     or (new_payload->>'last_slot')::numeric not in (0,1,2,3,4) then
    raise exception 'Invalid character slots' using errcode = '22023';
  end if;
  for entry in select value from jsonb_array_elements(new_payload->'slots') loop
    if jsonb_typeof(entry) not in ('null','object') then
      raise exception 'Invalid character data' using errcode = '22023';
    end if;
    if jsonb_typeof(entry) = 'object' and (
      jsonb_typeof(entry->'player_name') is distinct from 'string'
      or jsonb_typeof(entry->'inventory') is distinct from 'object'
      or jsonb_typeof(entry->'save_point') is distinct from 'array'
    ) then
      raise exception 'Invalid character data' using errcode = '22023';
    end if;
  end loop;
  insert into public.account_saves(user_id,payload)
    values(owner_id,'{"schema":1,"slots":[null,null,null,null,null],"last_slot":0}')
    on conflict (user_id) do nothing;
  select revision into current_revision from public.account_saves
    where user_id = owner_id for update;
  if current_revision <> expected_revision then
    return jsonb_build_object('ok',false,'revision',current_revision);
  end if;
  update public.account_saves set payload = new_payload,
    revision = current_revision + 1, updated_at = now() where user_id = owner_id;
  return jsonb_build_object('ok',true,'revision',current_revision + 1);
end;
$$;
revoke all on function public.save_account(bigint,jsonb) from public, anon;
grant execute on function public.save_account(bigint,jsonb) to authenticated;
commit;
