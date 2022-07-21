class role::mediawiki::jobrunner {
    system::role { 'mediawiki::jobrunner': }

    include ::profile::base::firewall

    # Parent role (we don't use inheritance by choice)
    include ::role::mediawiki::common

    include ::profile::prometheus::apache_exporter
    include ::profile::mediawiki::jobrunner
    include ::profile::mediawiki::videoscaler
    include ::profile::mediawiki::php::monitoring

    # restart php-fpm if the opcache available is too low
    include ::profile::mediawiki::php::restarts

    # not included in beta
    include ::profile::lvs::realserver
    include ::profile::tlsproxy::envoy
}
