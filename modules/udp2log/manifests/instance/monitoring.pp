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
    $packet_loss_log     = undef,
    $monitor_packet_loss = true,
    $monitor_processes   = true,
    $monitor_log_age     = true,
) {
    require udp2log::monitoring

    # Monitoring configs.
    # There are 3 ways udp2log instances are currently defined:
    # - Check age of udp2log files.
    # - Check that udp2log filter processes are running.
    # - Check the packet-loss log file for execessive packet loss.
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
        }
    }
    # TODO else ensure absent,
    # can't do this right now due to missing dependencies

    # Monitor that each filter process defined in
    # /etc/udp2log/$name is running
    if ($ensure_monitor_processes == true and $ensure == 'running') {
        nrpe::monitor_service { "udp2log_procs-${name}":
            ensure        => 'present',
            description   => "udp2log processes for ${name}",
            nrpe_command  => "/usr/lib/nagios/plugins/check_udp2log_procs ${name}",
            contact_group => 'admins,analytics',
            retries       => 10,
        }
    }
    # TODO else ensure absent,
    # can't do this right now due to missing dependencies

    # Monitor packet loss using the $packet_loss_log.
    # This requires that filters.$name.erb has a
    # packet-loss filter defined and outputting
    # to $packet_loss_log_file.
    if ($monitor_packet_loss == true and $ensure == 'running') {
        $ensure_monitor_packet_loss = 'present'
    }
    else {
        $ensure_monitor_packet_loss = 'absent'
    }

    # The packet loss file by default is in
    # $log_directory/packet-loss.log.  If it was
    # passed in explicitly, then use the value given.
    $packet_loss_log_file = $packet_loss_log ? {
        undef   => "${log_directory}/packet-loss.log",
        default => $packet_loss_log,
    }

    if ($monitor_packet_loss == true) {
        # Set up a cron to tail the packet loss log for this
        # instance into ganglia.
        cron { "ganglia-logtailer-udp2log-${name}":
            ensure  => $ensure_monitor_packet_loss,
            command => "/usr/sbin/ganglia-logtailer --classname PacketLossLogtailer --log_file ${packet_loss_log_file} --mode cron >> /var/log/ganglia/ganglia-logtailer.log 2>&1 ",
            user    => 'root',
            minute  => '*/5',
        }

        # Set up nagios monitoring of packet loss
        # for this udp2log instance.
        monitoring::ganglia{ "udp2log-${name}-packetloss":
            ensure                => $ensure_monitor_packet_loss,
            description           => 'Packetloss_Average',
            metric                => 'packet_loss_average',
            warning               => '4',
            critical              => '8',
            contact_group         => 'admins,analytics',
            # ganglia-logtailer only runs every 5.
            # let's make nagios check every 2 minutes (to match ganglia_parser)
            # and retry 4 times (total 8 minutes) before
            # declaring a hard failure.
            normal_check_interval => 2,
            retry_check_interval  => 2,
            retries               => 4,
        }
    }
    # TODO else ensure absent,
    # can't do this right now due to missing dependencies
}