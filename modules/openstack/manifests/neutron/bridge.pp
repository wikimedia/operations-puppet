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
            exec { "create-${name}-bridge-${addif}":
                command   => "/sbin/brctl addif ${name} ${addif}",
                unless    => "/sbin/brctl show ${name} | /bin/grep ${addif}",
                subscribe => Exec["create-${name}-bridge"],
            }

            # if the interface is managed by Puppet, ensure it's created first
            Exec <| tag == "interface-create-${addif}" |>
                -> Exec["create-${name}-bridge-${addif}"]
        }
    }

    file { "/etc/network/interfaces.d/${name}":
        ensure    => $ensure,
        owner     => 'root',
        group     => 'root',
        mode      => '0644',
        content   => template('openstack/neutron/bridge.erb'),
        subscribe => Exec["create-${name}-bridge"],
    }
}
