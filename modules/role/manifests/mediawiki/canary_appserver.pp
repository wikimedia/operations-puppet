# Class for a subgroup of appservers where we can test experimental features
class role::mediawiki::canary_appserver {
    include role::mediawiki::appserver

    include ::profile::mediawiki::canary_appserver
}
