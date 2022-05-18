# == Class: eventlogging::monitoring::jobs
#
# Installs an icinga check to make sure all defined
# eventlogging services are running.
#
class eventlogging::monitoring::jobs($ensure = 'present') {
    file { '/usr/lib/nagios/plugins/check_eventlogging_jobs':
        ensure => absent,
    }

    nrpe::plugin { 'check_eventlogging_jobs':
        ensure => $ensure,
        source => 'puppet:///modules/eventlogging/check_eventlogging_jobs.systemd',
    }

    nrpe::monitor_service { 'eventlogging-jobs':
        ensure        => $ensure,
        description   => 'Check status of defined EventLogging jobs',
        nrpe_command  => '/usr/local/lib/nagios/plugins/check_eventlogging_jobs',
        contact_group => 'admins,analytics',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/EventLogging',
    }
}
