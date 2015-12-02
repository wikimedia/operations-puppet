# Class for a subgroup of appservers where we can test experimental features
class role::mediawiki::appserver::canary_api {
    # salt -G 'canary:api_appserver' will select servers with this role.'
    salt::grain { 'canary': value => 'api_appserver' }
    include role::mediawiki::appserver::api
}

