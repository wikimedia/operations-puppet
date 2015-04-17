# == Class zuul::monitoring::merger
#
# Icinga monitoring for the Zuul merger
#
class zuul::monitoring::merger {

    nrpe::monitor_service { 'zuul_merger':
        description   => 'zuul_merger_service_running',
        contact_group => 'contint',
        nrpe_command  => "/usr/lib/nagios/plugins/check_procs -w 1:1 -c 1:1 --ereg-argument-array '^/usr/share/python/zuul/bin/python /usr/bin/zuul-merger'"
    }

}
