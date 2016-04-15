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
