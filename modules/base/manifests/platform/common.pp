class base::platform::common($lom_serial_port, $lom_serial_speed) {
    $console_upstart_file = "
# ${lom_serial_port} - getty
#
# This service maintains a getty on ${lom_serial_port} from the point the system is
# started until it is shut down again.

start on stopped rc RUNLEVEL=[2345]
stop on runlevel [!2345]

respawn
exec /sbin/getty -L ${lom_serial_port} ${lom_serial_speed} vt102
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