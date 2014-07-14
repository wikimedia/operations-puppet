#   Class: base::platform
#
#   This class implements hardware platform specific configuration
class base::platform {
    case $::productname {
        'PowerEdge C2100': {
            $startup_drives = [ '/dev/sda', '/dev/sdb' ]
        }
        'PowerEdge R300': {
            $startup_drives = [ '/dev/sda', '/dev/sdb']
            include base::platform::dell-r300
        }
        'R250-2480805': {
            $startup_drives = [ '/dev/sda', '/dev/sdb' ]
            include base::platform::cisco-C250-M1
        }
        default: {
            # set something so the logic doesn't puke
            $startup_drives = [ '/dev/sda', '/dev/sdb' ]
        }
    }
}

class base::platform::common($lom_serial_port, $lom_serial_speed) {
    $console_upstart_file = "
# ${lom_serial_port} - getty
#
# This service maintains a getty on ${lom_serial_port} from the point the system is
# started until it is shut down again.

start on stopped rc RUNLEVEL=[2345]
stop on runlevel [!2345]

respawn
exec /sbin/getty -L ${lom_serial_port} ${$lom_serial_speed} vt102
"

    if $::lsbdistid == 'Ubuntu' and versioncmp($::lsbdistrelease, '10.04') >= 0 {
        file { "/etc/init/${lom_serial_port}.conf":
            owner   => root,
            group   => root,
            mode    => '0444',
            content => $console_upstart_file;
        }
        generic::upstart_job { $lom_serial_port: require => File["/etc/init/${lom_serial_port}.conf"] }
    }
}

class base::platform::dell-c2100 inherits base::platform::generic::dell {
    $lom_serial_speed = '115200'

    class { 'common': lom_serial_port => $lom_serial_port, lom_serial_speed => $lom_serial_speed }
}

class base::platform::dell-r300 inherits base::platform::generic::dell {
    $lom_serial_speed = '57600'

    class { 'common': lom_serial_port => $lom_serial_port, lom_serial_speed => $lom_serial_speed }
}

class base::platform::cisco-C250-M1 inherits base::platform::generic::cisco {
    class { 'common': lom_serial_port => $lom_serial_port, lom_serial_speed => $lom_serial_speed }
}

class base::platform::generic::dell {
    $lom_serial_port = 'ttyS1'
}

class base::platform::generic::cisco {
    $lom_serial_port = 'ttyS0'
    $lom_serial_speed = '115200'
}

