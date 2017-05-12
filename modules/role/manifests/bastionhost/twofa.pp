class role::bastionhost::twofa {
    system::role { 'bastionhost::twofa':
        description => 'Bastion host using two factor authentication',
    }

    include ::standard
    include ::base::firewall
    include ::bastionhost
    include ::profile::bastionhost::twofa
    include ::profile::backup::host
    include ::passwords::yubiauth
    backup::set {'home': }
}
