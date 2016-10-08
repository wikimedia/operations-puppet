class role::swift::storage {
    system::role { 'role::swift::storage':
        description => 'swift storage brick',
    }

    include standard
    include base::firewall
    include ::profile::statsite
    include ::profile::swift::base
    include ::profile::swift::storage

}
