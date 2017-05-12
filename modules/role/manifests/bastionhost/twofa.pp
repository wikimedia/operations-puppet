# bastion host using two-factor auth
class role::bastionhost::twofa {

    system::role { 'bastionhost::twofa':
        description => 'experimental Bastion host using YubiKey two factor authentication',
    }

    include ::standard
    include ::base::firewall
    include ::bastionhost
    include ::profile::bastionhost::twofa
    include ::profile::backup::host
    include ::passwords::yubiauth
    include ::role::access_new_install
    backup::set {'home': }
}
