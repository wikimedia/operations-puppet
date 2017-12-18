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

    class { '::thumbor::nutcracker':
        thumbor_memcached_servers => hiera('thumbor_memcached_servers_nutcracker')
    }

    class { '::thumbor': }

    include ::swift::params
    $swift_account_keys = $::swift::params::account_keys

    class { '::thumbor::swift':
        swift_key                => $swift_account_keys['mw_thumbor'],
        swift_sharded_containers => hiera_array('swift::proxy::shard_container_list'),
    }

    include ::lvs::realserver

    ferm::service { 'thumbor':
        proto  => 'tcp',
        port   => '8800',
        srange => '$DOMAIN_NETWORKS',
    }

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
