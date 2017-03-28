# = Class: profile::yubiauth::server
#
# This class configures a Yubi 2FA authentication server
#
class profile::yubiauth::server (
    $auth_servers = hiera('yubiauth_servers'),
    $auth_server_primary = hiera('yubiauth_server_primary'),
) {

    $auth_servers_ferm = join($auth_servers, ' ')

    include ::base::firewall

    class {'::yubiauth::yhsm_daemon': }

    class {'::yubiauth::yhsm_yubikey_ksm': }

    backup::set { 'yubiauth-aeads' : }

    if ($::fqdn == $auth_server_primary) {

        class { 'yubiauth::yhsm_aead_sync':
            sync_allowed => $auth_servers,
        }

        ferm::service {'yubiauth_rsync':
            port   => '873',
            proto  => 'tcp',
            srange => "@resolve((${auth_servers_ferm}))",
        }
    }
    else {
        cron { 'sync AEAD files from primary auth server':
            command => "/usr/bin/rsync -az ${auth_server_primary}::aead_sync /var/cache/yubikey-ksm/aeads",
            user    => 'root',
            minute  => '*/30',
        }
    }

    system::role { 'profile::yubiauth::server':
        ensure      => 'present',
        description => 'Yubi 2FA authentication server',
    }

    ferm::service { 'yubikey-validation-server':
        proto  => 'tcp',
        port   => '80',
        srange => '$BASTION_HOSTS',
    }
}
