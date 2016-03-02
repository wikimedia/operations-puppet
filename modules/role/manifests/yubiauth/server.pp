# = Class: role::yubiauth
#
# This class configures a Yubi 2FA authentication server
#
class role::yubiauth::server {
    include standard
    include base::firewall

    include yubiauth::yhsm_daemon
    include yubiauth::yhsm_yubikey_ksm

    system::role { 'role::yubiauth':
        ensure      => 'present',
        description => 'Yubi 2FA authentication server',
    }
}
