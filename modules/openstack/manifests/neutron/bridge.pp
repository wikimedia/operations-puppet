define openstack::neutron::bridge(
    $addif=undef,
    $ensure='present',
    ) {

    if ($ensure == 'present') {

        exec {"create-${name}-bridge":
            command => "/sbin/brctl addbr ${name}",
            unless  => "/sbin/brctl show | /bin/grep ${name}",
        }

        # this is hokey but solves the simple case for neutron at the moment
        if ($addif) {
            exec {"create-${name}-bridge-${addif}":
                command     => "/sbin/brctl addif ${name} ${addif}",
                unless      => "/sbin/brctl show ${name} | /bin/grep ${addif}",
                subscribe   => Exec["create-${name}-bridge"],
                refreshonly => true,
            }
        }
    }
}
