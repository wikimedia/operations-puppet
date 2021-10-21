# - $oauth_consumer_key: oauth consumer key
# - $auth_consumer_secret: oauth consumer secret
# - $oauth_nice_url: "nice" url for oauth 1.0a mwapi - required for certain calls
# - $oauth_index_url: "index.php" url for oauth 1.0a mwapi - required for certain calls (different than nice url)
# - $oauth_wiki_logout_link: URL the user is forwarded to after logging out
# - $oauth_success_redirect_url:  URL the user is forwarded to after authentication success
# - $oauth_session_store_host: Host to connect to for session storage (expecting kask)
# - $oauth_session_store_port: Port to connect to on session store for http kask api
# - $oauth_access_token_secret: Secret value used to sign and verify JWT access tokens
type Query_service::OAuthSettings = Struct[{
  'oauth_consumer_key'         => String,
  'oauth_consumer_secret'      => String,
  'oauth_nice_url'             => Stdlib::HTTPSUrl,
  'oauth_index_url'            => Stdlib::HTTPSUrl,
  'oauth_wiki_logout_link'     => Stdlib::HTTPSUrl,
  'oauth_success_redirect_url' => Stdlib::HTTPSUrl,
  'oauth_session_store_host'   => String,
  'oauth_session_store_port'   => Integer,
  'oauth_access_token_secret'  => String,
}]
