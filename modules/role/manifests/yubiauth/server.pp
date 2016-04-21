# = Class: role::yubiauth
#
# This class configures a Yubi 2FA authentication server
#
class role::yubiauth::server {
    include standard
    include base::firewall
    include ::role::backup::host

    include yubiauth::yhsm_daemon
    include yubiauth::yhsm_yubikey_ksm

    backup::set { 'yubiauth-aeads' : }

    $auth_servers = hiera('yubiauth_servers')
    $auth_servers_ferm = join($auth_servers, ' ')
    $auth_server_primary = hiera('yubiauth_server_primary')

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

    system::role { 'role::yubiauth':
        ensure      => 'present',
        description => 'Yubi 2FA authentication server',
    }

    ferm::service { 'yubikey-validation-server':
        proto  => 'tcp',
        port   => '80',
        srange => '$BASTION_HOSTS',
    }
}
