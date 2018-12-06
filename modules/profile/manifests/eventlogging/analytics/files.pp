# == Class profile::eventlogging::analytics::files
#
# Consumes streams of events and writes them to log files.
#
class profile::eventlogging::analytics::files(
    $backup_destinations = hiera('statistics_servers', undef)
) {

    require profile::eventlogging::analytics::server

    # Log all raw log records and decoded events to flat files in
    # $out_dir as a medium of last resort. These files are rotated
    # and rsynced to some stat hosts for backup.

    $out_dir = '/srv/log/eventlogging'
    $logs_dir_owner = 'eventlogging'
    $logs_dir_group = 'eventlogging'

    # Logs are collected in <$log_dir> and rotated daily.
    file { [$out_dir, "${out_dir}/archive"]:
        ensure => 'directory',
        owner  => $logs_dir_owner,
        group  => $logs_dir_group,
        mode   => '0664',
    }

    # Log retention in labs is not important and might
    # end up consuming a sizeable chunk of the disk partiton
    # in which it is placed (usually the root one).
    #
    # Reduced the max age in T206542 due to an increase
    # in events handled and consequent disk space consumption increase.
    # These logs are rsynced to stat1007 and kept for 90 days,
    # so safe to apply a stricter retention rule.
    $logs_max_age = $::realm ? {
        'labs'  => 4,
        default => 7,
    }

    logrotate::conf { 'eventlogging-files':
        ensure  => 'present',
        content => template('profile/eventlogging/analytics/files_logrotate.erb'),
        require => [
            File[$out_dir],
            File["${out_dir}/archive"]
        ],
    }

    # These commonly used URIs are defined for DRY purposes in
    # profile::eventlogging::analytics::server.
    $kafka_client_side_raw_uri = $profile::eventlogging::analytics::server::kafka_client_side_raw_uri
    $kafka_mixed_uri           = $profile::eventlogging::analytics::server::kafka_mixed_uri

    # Raw client side events:
    eventlogging::service::consumer { 'client-side-events.log':
        input  => "${kafka_client_side_raw_uri}&raw=True",
        output => "file://${out_dir}/client-side-events.log",
        sid    => 'eventlogging_consumer_client_side_events_log_00',
    }
    # Processed and valid all (AKA 'mixed').
    # Note that this does not include events that were
    # 'blacklisted' during processing.  Events are blacklisted
    # from these logs for volume reasons.
    eventlogging::service::consumer { 'all-events.log':
        input  => $kafka_mixed_uri,
        output => "file://${out_dir}/all-events.log",
        sid    => 'eventlogging_consumer_all_events_log_00',
    }

    if ( $backup_destinations ) {
        class { 'rsync::server': }

        rsync::server::module { 'eventlogging':
            path        => $out_dir,
            read_only   => 'yes',
            list        => 'yes',
            require     => File[$out_dir],
            hosts_allow => $backup_destinations,
            auto_ferm   => true,
        }
    }
}
