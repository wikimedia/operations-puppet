# == Define udp2log::instance::monitoring
# Monitoring configs for a udp2log instance.
# This is abstracted out of the udp2log::instance
# define so it is possible to monitor non-puppetized
# udp2log instances.
#
# == Parameters:
# See documentation for udp2log::instance.
#
define udp2log::instance::monitoring(
    $log_directory       = '/var/log/udp2log',
    $ensure              = 'running',
    $monitor_processes   = true,
    $monitor_log_age     = true,
) {
    require udp2log::monitoring

    # Monitoring configs.
    # There are 3 ways udp2log instances are currently defined:
    # - Check age of udp2log files.
    # - Check that udp2log filter processes are running.
    # These different monitors are enabled or disabled using
    # their corresponding $monitor_xxxxx arguments passed into
    # this class.

    # Monitor age of log udp2log files.
    if ($monitor_log_age == true and $ensure == 'running') {
        nrpe::monitor_service { "udp2log_log_age-${name}":
            ensure        => 'present',
            description   => "udp2log log age for ${name}",
            nrpe_command  => "/usr/lib/nagios/plugins/check_udp2log_log_age ${name}",
            contact_group => 'admins,analytics',
            notes_url     => 'https://wikitech.wikimedia.org/wiki/Udp2log',
        }
    }
    # TODO else ensure absent,
    # can't do this right now due to missing dependencies

    # Monitor that each filter process defined in
    # /etc/udp2log/$name is running
    if ($monitor_processes == true and $ensure == 'running') {
        nrpe::monitor_service { "udp2log_procs-${name}":
            ensure        => 'present',
            description   => "udp2log processes for ${name}",
            nrpe_command  => "/usr/lib/nagios/plugins/check_udp2log_procs ${name}",
            contact_group => 'admins,analytics',
            retries       => 10,
            notes_url     => 'https://wikitech.wikimedia.org/wiki/Udp2log',
        }
    }
    # TODO else ensure absent,
    # can't do this right now due to missing dependencies
}
