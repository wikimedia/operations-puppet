# == class tc ==
#
# Allows for setting up traffic control scripts to be run
# at boot time (and on change) in a way that works
# regardless of OS flavour.
#
# It constructs a tree, at /etc/tc, that contains one directory
# (named $iface.d) for every interface to manage tc for, and
# the upstart/systemd scripts to enable tc by running their
# contents with run-parts
#

class tc {

    file { '/etc/tc':
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
    }

    file { '/usr/local/sbin/apply-tc':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        source  => 'puppet:///modules/tc/apply-tc',
    }

    base::service_unit { 'tc':
        ensure  => present,
        strict  => true,
        upstart => true,
        systemd => true,
        refresh => true,
    }

}

