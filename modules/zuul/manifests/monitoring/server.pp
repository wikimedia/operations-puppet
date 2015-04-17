# == Class zuul::monitoring::server
#
# Icinga monitoring for the Zuul server
#
class zuul::monitoring::server {

    nrpe::monitor_service { 'zuul':
        description   => 'zuul_service_running',
        contact_group => 'contint',
        # Zuul has a main process and a fork which is the gearman
        # server. Thus we need two process running.
        nrpe_command  => "/usr/lib/nagios/plugins/check_procs -w 2:2 -c 2:2 --ereg-argument-array '^/usr/share/python/zuul/bin/python /usr/bin/zuul-server'",
    }

    nrpe::monitor_service { 'zuul_gearman':
        description   => 'zuul_gearman_service',
        contact_group => 'contint',
        nrpe_command  => '/usr/lib/nagios/plugins/check_tcp -H 127.0.0.1 -p 4730 --timeout=2',
    }

}
