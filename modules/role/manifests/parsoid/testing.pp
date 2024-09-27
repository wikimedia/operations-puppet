# Parsoid testing, MW appserver plus parsoid testing setup
class role::parsoid::testing {
    ## Basics
    include profile::base::production
    include profile::firewall

    ## Parsoid
    include profile::nginx
    include profile::parsoid::testing

    ## MediaWiki
    # We don't include things like automatic php restarts
    # or prometheus exporters, as this is just a testing
    # installation.
    # We do include auto_restart services to be used after library upgrades.
    include profile::parsoid::mediawiki
    include role::mediawiki::common
    include profile::mediawiki::php
    include profile::mediawiki::php::monitoring
    include profile::mediawiki::webserver
}
