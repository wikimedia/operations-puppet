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
    include ::profile::conftool::client

    class { 'conftool::scripts': }

    class { '::memcached':
        size => 100,
        port => 11211,
    }

    $thumbor_memcached_servers_ferm = join(hiera('thumbor_memcached_servers'), ' ')

    ferm::service { 'memcached_memcached_role':
        proto  => 'tcp',
        port   => '11211',
        srange => "(@resolve((${thumbor_memcached_servers_ferm})))",
    }

    class { 'threedtopng::deploy':
        manage_user => true,
    }
}
