# == Class: role::thumbor::mediawiki
#
# Installs a Thumbor image scaling server to be used with MediaWiki.
#

class role::thumbor::mediawiki {
    include base::firewall
    include role::statsite


    class { '::thumbor': }

    $swift_account_keys = $swift::params::account_keys

    class { '::thumbor::swift':
        swift_key                => $swift_account_keys['thumbor'],
        swift_sharded_containers => hiera_array('swift::proxy::shard_container_list'),
    }

    ferm::service { 'thumbor':
        proto  => 'tcp',
        port   => '8800',
        srange => '$DOMAIN_NETWORKS',
    }
}
