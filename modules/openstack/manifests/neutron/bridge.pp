define openstack::neutron::bridge(
    $brname,
    $interface='',
    $ensure='present',
    ) {

    if ($ensure == 'present') {

        exec {"create-${brname}-bridge":
            command => "/sbin/brctl addbr ${brname}",
            unless  => "/sbin/brctl show | /bin/grep ${brname}",
            notify  => Exec["create-${brname}-bridge-${interface}"],
        }

        # this is hokey but solves the simple case for neutron at the moment
        if ($interface) {
            exec {"create-${brname}-bridge-${interface}":
                command     => "/sbin/brctl addif ${brname} ${interface}",
                unless      => "/sbin/brctl show ${brname} | /bin/grep ${interface}",
                refreshonly => true,
            }
        }
    }
}
