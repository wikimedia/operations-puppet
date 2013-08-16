# Definition: nrpe::check
#
# Installs a single NRPE check in /etc/nagios/nrpe.d/
#
# Parameters:
#   $title (implicit parameter)
#       Name of the check, referenced by monitor_service and check_command
#       e.g. check_varnishhtcpd
#   $command
#       Command run by NRPE,
#       e.g. "/usr/lib/nagios/plugins/check_procs -c 1:1 -C varnishtcpd"
# Actions:
#       Install a NRPE check definition in /etc/nagios/nrpe.d/
#
# Requires:
#   Class[nrpe]
#
# Sample Usage:
#   nrpe::check { 'check_myprocess':
#       $command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C myprocess'
#   }

define nrpe::check($command) {
    if !defined(Class['nrpe']) {
        class {'nrpe': }
    }

    file { "/etc/nagios/nrpe.d/${title}.cfg":
        owner   => root,
        group   => root,
        mode    => '0444',
        content => template('nrpe/check.erb'),
        notify  => Service['nagios-nrpe-server']
    }
}
