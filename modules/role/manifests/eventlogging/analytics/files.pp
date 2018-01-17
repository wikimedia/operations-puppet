# == Class role::eventlogging::analytics::files
# Consumes streams of events and writes them to log files.
#
# filtertags: labs-project-deployment-prep
class role::eventlogging::analytics::files {
    include role::eventlogging::analytics::server

    # Log all raw log records and decoded events to flat files in
    # $out_dir as a medium of last resort. These files are rotated
    # and rsynced to some stat hosts for backup.

    $out_dir = '/srv/log/eventlogging'

    # We ensure the /srv/log (parent of $out_dir) manually here, as
    # there is no proper class to rely on for this, and starting a
    # separate would be an overkill for now.
    if !defined(File['/srv/log']) {
        file { '/srv/log':
            ensure => 'directory',
            mode   => '0755',
            owner  => 'root',
            group  => 'root',
        }
    }

    # Logs are collected in <$log_dir> and rotated daily.
    file { [$out_dir, "${out_dir}/archive"]:
        ensure => 'directory',
        owner  => 'eventlogging',
        group  => 'eventlogging',
        mode   => '0664',
    }

    logrotate::conf { 'eventlogging-files':
        ensure  => 'present',
        content => template('role/eventlogging/analytics/files_logrotate.erb'),
        require => [
            File[$out_dir],
            File["${out_dir}/archive"]
        ],
    }

    $kafka_consumer_group = hiera(
        'eventlogging_files_kafka_consumer_group',
        'eventlogging_consumer_files_00'
    )

    # These commonly used URIs are defined for DRY purposes in
    # role::eventlogging::analytics::server.
    $kafka_client_side_raw_uri = $role::eventlogging::analytics::server::kafka_client_side_raw_uri
    $kafka_mixed_uri           = $role::eventlogging::analytics::server::kafka_mixed_uri

    # Raw client side events:
    eventlogging::service::consumer { 'client-side-events.log':
        input  => "${kafka_client_side_raw_uri}&raw=True",
        output => "file://${out_dir}/client-side-events.log",
        sid    => $kafka_consumer_group,
    }
    # Processed and valid all (AKA 'mixed').
    # Note that this does not include events that were
    # 'blacklisted' during processing.  Events are blacklisted
    # from these logs for volume reasons.
    eventlogging::service::consumer { 'all-events.log':
        input  => $kafka_mixed_uri,
        output => "file://${out_dir}/all-events.log",
        sid    => $kafka_consumer_group,
    }

    $backup_destinations = $::realm ? {
        production => hiera('statistics_servers'),
        labs       => false,
    }

    if ( $backup_destinations ) {
        class { 'rsync::server': }

        $rsync_clients_ferm = join($backup_destinations, ' ')
        ferm::service { 'eventlogging_rsyncd':
            proto  => 'tcp',
            port   => '873',
            srange => "@resolve((${rsync_clients_ferm}))",
        }

        rsync::server::module { 'eventlogging':
            path        => $out_dir,
            read_only   => 'yes',
            list        => 'yes',
            require     => File[$out_dir],
            hosts_allow => $backup_destinations,
        }
    }
}
