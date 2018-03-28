define openstack::neutron::bridge(
    $brname,
    $ensure='present',
    $addif=undef,
    ) {

    if ($ensure == 'present') {

        exec {"create-${brname}-bridge":
            command => "/sbin/brctl addbr ${brname}",
            unless  => "/sbin/brctl show | /bin/grep ${brname}",
            notify  => Exec["create-${brname}-bridge-${addif}"],
        }

        # this is hokey but solves the simple case for neutron at the moment
        if ($addif) {
            exec {"create-${brname}-bridge-${addif}":
                command     => "/sbin/brctl addif ${brname} ${addif}",
                unless      => "/sbin/brctl show ${brname} | /bin/grep ${addif}",
                refreshonly => true,
            }
        }
    }
}
