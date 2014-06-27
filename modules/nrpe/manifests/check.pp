# Definition: nrpe::check
#
# Installs a single NRPE check in /etc/nagios/nrpe.d/
# Please do note that this definition might be used on machines where the nrpe
# class is not included. In that case it will be a no-op since the definition
# will not be realized
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
#   Class[nrpe] (optionally)
#
# Sample Usage:
#   nrpe::check { 'check_myprocess':
#       $command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C myprocess'
#   }
#
define nrpe::check($command, $ensure='present') {
    # If the nrpe class is not included, this entire definition will never be
    # realized making it a no-op
    $title_safe  = regsubst($title, '[\W]', '-', 'G')
    @file { "/etc/nagios/nrpe.d/${title_safe}.cfg":
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('nrpe/check.erb'),
        notify  => Service['nagios-nrpe-server'],
        tag     => 'nrpe::check',
    }
}
