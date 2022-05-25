# Definition: nrpe::check
#
# Installs a single NRPE check in /etc/nagios/nrpe.d/
# Please do note that this definition might be used on machines where the nrpe
# class is not included. In that case it will be a no-op since the definition
# will not be realized
#
# Parameters:
#   $title (implicit parameter)
#       Name of the check, referenced by monitoring::service and check_command
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
define nrpe::check(
    Optional[String] $command   = undef,
    Optional[String] $sudo_user = undef,
    Wmflib::Ensure   $ensure    = 'present'
) {
    $title_safe  = regsubst($title, '[\W]', '-', 'G')

    if $ensure == 'present' and !$command {
        fail('command is required when ensure => present')
    }

    $real_command = $sudo_user ? {
        undef   => $command,
        'root'  => "/usr/bin/sudo ${command}",
        default => "/usr/bin/sudo -u ${sudo_user} ${command}",
    }

    @file { "/etc/nagios/nrpe.d/${title_safe}.cfg":
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('nrpe/check.erb'),
        notify  => Service['nagios-nrpe-server'],
        tag     => 'nrpe::check',
    }

    if $sudo_user  {
        @sudo::user { "nrpe-${title}":
            ensure     => $ensure,
            user       => 'nagios',
            privileges => [
                "ALL = (${sudo_user}) NOPASSWD: ${command}",
            ],
            tag        => 'nrpe::check',
        }
    } else {
        @sudo::user { "nrpe-${title}":
            ensure     => absent,
            user       => 'nagios',
            privileges => [],
            tag        => 'nrpe::check',
        }
    }
}
