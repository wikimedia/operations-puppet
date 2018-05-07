# == Class: role::thumbor::mediawiki
#
# Installs a Thumbor image scaling server to be used with MediaWiki.
#
# filtertags: labs-project-deployment-prep

class role::thumbor::mediawiki {
    include ::standard
    include ::base::firewall
    include ::mediawiki::packages::fonts
    include role::statsite
    include ::profile::prometheus::nutcracker_exporter
    include ::profile::thumbor
    include ::lvs::realserver
    include ::threedtopng::deploy # lint:ignore:wmf_styleguide

    class { '::memcached':
        size => 100,
        port => 11211,
    }

    include ::profile::prometheus::memcached_exporter

    $thumbor_memcached_servers_ferm = join(hiera('thumbor_memcached_servers'), ' ')

    ferm::service { 'memcached_memcached_role':
        proto  => 'tcp',
        port   => '11211',
        srange => "(@resolve((${thumbor_memcached_servers_ferm})))",
    }
}
