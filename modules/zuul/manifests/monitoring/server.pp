# == Class zuul::monitoring::server
#
# Icinga monitoring for the Zuul server
#
# == Parameters
#
# [*ensure*]
#
class zuul::monitoring::server (
    $ensure = present,
) {
    validate_ensure($ensure)

    # only monitor these on the active master host
    # zuul service will be stopped on the warm standby server
    nrpe::monitor_service { 'zuul':
        ensure        => $ensure,
        description   => 'zuul_service_running',
        contact_group => 'contint',
        # Zuul has a main process and a fork which is the gearman
        # server. Thus we need two process running.
        nrpe_command  => "/usr/lib/nagios/plugins/check_procs -w 2:2 -c 2:2 --ereg-argument-array '^/usr/share/python/zuul/bin/python /usr/bin/zuul-server'",
    }

    nrpe::monitor_service { 'zuul_gearman':
        ensure        => $ensure,
        description   => 'zuul_gearman_service',
        contact_group => 'contint',
        nrpe_command  => '/usr/lib/nagios/plugins/check_tcp -H 127.0.0.1 -p 4730 --timeout=2',
    }
}
