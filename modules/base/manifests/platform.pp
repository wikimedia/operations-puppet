#   Class: base::platform
#
#   This class implements hardware platform specific configuration
class base::platform {
    case $::productname {
        'PowerEdge C2100': {
            $startup_drives   = [ '/dev/sda', '/dev/sdb' ]
            $lom_serial_port  = 'ttyS1'
            $lom_serial_speed = '115200'
        }
        'PowerEdge R300': {
            $startup_drives   = [ '/dev/sda', '/dev/sdb']
            $lom_serial_port  = 'ttyS1'
            $lom_serial_speed = '57600'
        }
        'R250-2480805': {
            $startup_drives   = [ '/dev/sda', '/dev/sdb' ]
            $lom_serial_port  = 'ttyS0'
            $lom_serial_speed = '115200'
        }
        default: {
            # set something so the logic doesn't puke
            $startup_drives = [ '/dev/sda', '/dev/sdb' ]
        }
    }

    if $::lsbdistid == 'Ubuntu' and versioncmp($::lsbdistrelease, '10.04') >= 0 {
        file { "/etc/init/${lom_serial_port}.conf":
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            content => template('base/console.erb'),
        }
        generic::upstart_job { $lom_serial_port:
            require => File["/etc/init/${lom_serial_port}.conf"],
        }
    }
}

