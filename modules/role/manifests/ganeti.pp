# Role classes for ganeti
class role::ganeti {

    system::role { 'ganeti':
        description => 'Ganeti Node',
    }

    include ::profile::base::production
    include ::profile::ganeti
    include ::profile::base::firewall
}
