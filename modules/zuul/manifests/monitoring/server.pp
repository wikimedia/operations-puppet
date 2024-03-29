# == Class zuul::monitoring::server
#
# Icinga and mtail monitoring for the Zuul server
#
# == Parameters
#
# [*ensure*]
#
class zuul::monitoring::server (
    Wmflib::Ensure $ensure = present,
) {

    # only monitor these on the active master host
    # zuul service will be stopped on the warm standby server
    nrpe::monitor_service { 'zuul':
        ensure        => $ensure,
        description   => 'zuul_service_running',
        contact_group => 'contint',
        # Zuul has a main process and a fork which is the gearman
        # server. Thus we need two process running.
        nrpe_command  => "/usr/lib/nagios/plugins/check_procs -w 2:2 -c 2:2 --ereg-argument-array 'bin/zuul-server'",
        notes_url     => 'https://www.mediawiki.org/wiki/Continuous_integration/Zuul',
    }

    nrpe::monitor_service { 'zuul_gearman':
        ensure        => $ensure,
        description   => 'zuul_gearman_service',
        contact_group => 'contint',
        nrpe_command  => '/usr/lib/nagios/plugins/check_tcp -H 127.0.0.1 -p 4730 --timeout=2',
        notes_url     => 'https://www.mediawiki.org/wiki/Continuous_integration/Zuul',
    }

    monitoring::graphite_threshold{ 'zuul_gearman_wait_queue':
        ensure          => $ensure,
        description     => 'Work requests waiting in Zuul Gearman server',
        dashboard_links => ['https://grafana.wikimedia.org/d/000000322/zuul-gearman?orgId=1&viewPanel=10'],
        metric          => 'zuul.geard.queue.waiting',
        contact_group   => 'contint',
        from            => '10min',
        percentage      => 100,
        warning         => 200,
        critical        => 400,
        notes_link      => 'https://www.mediawiki.org/wiki/Continuous_integration/Zuul',
    }

    # Installs a particular mtail program into /etc/mtail/
    mtail::program { 'zuul_error_log':
      source => 'puppet:///modules/mtail/programs/zuul_error_log.mtail',
    }
}
