# Continuous Integration Server (contint)
# https://en.wikipedia.org/wiki/Continuous_integration
# https://integration.wikimedia.org/
class role::contint_server {

    system::role { 'contint_server': description => 'Continuous Integration Server' }

    include ::standard
    include ::contint::firewall

    include ::profile::ci::master
    include ::profile::ci::slave
    include ::profile::ci::website
    include ::profile::zuul::merger
    include ::profile::zuul::server
    include ::profile::mediawiki::deployment::server
    include ::profile::backup::host
    include ::role::deployment::mediawiki
    include ::role::microsites::releases::upload
}
