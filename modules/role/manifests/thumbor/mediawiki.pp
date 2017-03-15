# == Class: role::thumbor::mediawiki
#
# Installs a Thumbor image scaling server to be used with MediaWiki.
#
# filtertags: labs-project-deployment-prep

class role::thumbor::mediawiki {
    include ::base::firewall
    include role::statsite

    class { '::thumbor::nutcracker':
        thumbor_memcached_servers => hiera('thumbor_memcached_servers')
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

    ferm::service { 'memcached_memcached_role':
        proto => 'tcp',
        port  => '11211',
    }
}
