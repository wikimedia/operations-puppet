# = Class: role::yubiauth
#
# This class configures a Yubi 2FA authentication server
#
class role::yubiauth {
    include standard
    include base::firewall

    system::role { 'role::yubiauth':
        ensure      => 'present',
        description => 'Yubi 2FA authentication server',
    }
}
