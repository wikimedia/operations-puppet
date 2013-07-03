# == Class: eventlogging::decommission
#
# This class automates the process of retiring an EventLogging node. It
# shuts down EventLogging services and removes their configuration data.
#
class eventlogging::decommission {
    exec { 'initctl emit eventlogging.stop':
        before => File['/etc/init/eventlogging', '/etc/eventlogging.d'],
    }

    file { [ '/etc/init/eventlogging', '/etc/eventlogging.d' ]:
        ensure  => absent,
        purge   => true,
        force   => true,
        recurse => true,
    }

    deployment::target { 'eventlogging':
        ensure => absent,
    }
}
