# Class for a subgroup of appservers where we can test experimental features
class role::mediawiki::appserver::canary_api {
    include role::mediawiki::appserver::api
    # restart php-fpm if the opcache available is too low
    include ::profile::mediawiki::php::restarts
}
