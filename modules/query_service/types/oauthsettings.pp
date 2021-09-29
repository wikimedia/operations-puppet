# - $oauth_consumer_key: oauth consumer key
# - $auth_consumer_secret: oauth consumer secret
# - $oauth_session_store_limit: how many concurrent token request and sessions should be remembered
# - $oauth_nice_url: "nice" url for oauth 1.0a mwapi - required for certain calls
# - $oauth_index_url: "index.php" url for oauth 1.0a mwapi - required for certain calls (different than nice url)
type Query_service::OAuthSettings = Struct[{
  'oauth_consumer_key'         => String,
  'oauth_consumer_secret'      => String,
  'oauth_session_store_limit'  => Integer,
  'oauth_nice_url'             => Stdlib::HTTPSUrl,
  'oauth_index_url'            => Stdlib::HTTPSUrl,
  'oauth_wiki_logout_link'     => Stdlib::HTTPSUrl,
}]
