class role::swift::proxy {
    system::role { 'role::swift::proxy':
        description => 'swift frontend proxy',
    }

    include standard
    include base::firewall
    include ::profile::statsite
    include ::profile::swift::base
    include ::profile::swift::proxy
}
