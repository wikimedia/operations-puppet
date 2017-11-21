# Role classes for ganeti
class role::ganeti {

    system::role { 'ganeti':
        description => 'Ganeti Node',
    }

    include ::standard
    include ::profile::ganeti
    include ::profile::base::firewall
}
