# == Class: role::gdash
#
# https://gdash.wikimedia.org/ is a static mirror of the site that was
# previously served at that URL -- a dashboard templating webapp for Graphite.
# At the time of writing (October 2015), we are in the process of migrating to
# Grafana (https://grafana.wikimedia.org), but gdash continues to receive
# traffic, so we preserved it here.
#
class role::gdash {
    include ::apache

    include ::apache::mod::expires
    include ::apache::mod::filter
    include ::apache::mod::headers
    include ::apache::mod::rewrite

    file { '/var/www/gdash.wikimedia.org':
        ensure  => directory,
        source => 'puppet:///files/gdash/docroot',
        recurse => true,
        owner   => 'root',
        group   => 'root',
        mode    => '0544',
    } ->

    apache::site { 'gdash.wikimedia.org':
        source  => 'puppet:///files/gdash/gdash.wikimedia.org.conf',
    }
}
