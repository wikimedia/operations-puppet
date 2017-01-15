# == Define: diamond::collector::nagios
#
# Report the return code of a nagios plugin
#
# === Parameters
#
#   command: List of arguments to run as a command
#
# === Examples
#
#   diamond::collector::nagios { 'keyholder_status':
#       command => [ '/usr/bin/sudo', '/usr/lib/nagios/plugins/check_keyholder' ]
#   }

define diamond::collector::nagios (
    $command = undef,
    $ensure = 'present',
) {
    validate_ensure($ensure)
    if $command == undef {
        fail('Command must be defined')
    }

    include ::diamond::collector::nagios_lib

    file { "/etc/diamond/nagios.d/${title}.json":
        ensure  => $ensure,
        content => ordered_json({
            name    => $title,
            command => $command,
        }),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service['diamond'],
    }
}

