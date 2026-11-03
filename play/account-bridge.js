// Discard obsolete email callback credentials. Game accounts use passwords now.
(() => {
  const params=new URLSearchParams(location.hash.slice(1));
  if(params.has('access_token')||params.has('error')){
    history.replaceState(null,'',location.pathname+location.search);
  }
  try{localStorage.removeItem('blockrealm.pending-email.gqbqbosjszmlhebbsbmy');}catch(_){}
})();
