# == Class profile::mariadb::misc::eventlogging::sanitization
#
# Deploys the eventlogging_cleaner.py script to apply Analytics data
# retention policies to the log database running in localhost.
#
# Parameters:
#
# [*extra_parameters*]
#   Extra parameters to add to the eventlogging cleaner cron in addition to the
#   hardcoded ones. This can be useful in environments like labs in which we can
#   use new/different parameters for testing.
#
class profile::mariadb::misc::eventlogging::sanitization(
    $extra_parameters = hiera('profile::mariadb::misc::eventlogging::sanitization::extra_parameters', ''),
) {
    # The eventlogging purging whitelist is provided by another profile
    # since it is shared with the Hive Eventlogging sanitization workflow.
    require ::profile::analytics::refinery::repository
    $whitelist_path = '/srv/deployment/analytics/refinery/static_data/eventlogging/whitelist.yaml'

    if !defined(Group['eventlog']) {
        group { 'eventlog':
            ensure => 'present',
            system => true,
        }
    }

    $log_directory_path = '/var/log/eventlogging_cleaner'
    $state_directory_path = '/srv/eventlogging_cleaner'

    user { 'eventlogcleaner':
        gid        => 'eventlog',
        shell      => '/bin/false',
        home       => '/nonexistent',
        comment    => 'EventLogging cleaner user',
        system     => true,
        managehome => false,
        require    => Group['eventlog'],
    }

    require_package([
        'python3-pymysql',
        'python3-yaml'
    ])

    file { '/usr/local/bin/eventlogging_cleaner':
        ensure  => present,
        owner   => 'eventlogcleaner',
        group   => 'eventlog',
        mode    => '0550',
        source  => 'puppet:///modules/profile/mariadb/misc/eventlogging/eventlogging_cleaner.py',
        require => Package['python3-pymysql'],
    }

    file { $log_directory_path:
        ensure => 'directory',
        owner  => 'root',
        group  => 'eventlog',
        mode   => '0775',
    }

    file { $state_directory_path:
        ensure => 'directory',
        owner  => 'root',
        group  => 'eventlog',
        mode   => '0775',
    }

    logrotate::rule { 'eventlogging-cleaner':
        ensure        => present,
        file_glob     => "${log_directory_path}/eventlogging_cleaner.log",
        frequency     => 'daily',
        copy_truncate => true,
        compress      => true,
        missing_ok    => true,
        not_if_empty  => true,
        rotate        => 14,
        su            => 'root eventlog',
    }

    # Sanitization of data in the log database via a custom script
    # The eventlogging_cleaner script uses the --start-ts-file file option,
    # that forces it to look for a file containing a timestamp in the format
    # %Y%m%d%H%M%S. If the file is not existent, the script will fail gracefully
    # without doing any action to the db. This is useful to avoid gaps in
    # records sanitized if the script fails and does not commit a new timestamp.
    $eventlogging_cleaner_command = "/usr/local/bin/eventlogging_cleaner --whitelist ${whitelist_path} --yaml --older-than 90 --start-ts-file ${state_directory_path}/eventlogging_cleaner --batch-size 10000 --sleep-between-batches 2 ${extra_parameters}"

    systemd::timer::job { 'eventlogging_db_sanitization':
        description               => 'Apply Analytics data retetion policies to the Eventlogging database',
        command                   => $eventlogging_cleaner_command,
        interval                  => {
            'start'    => 'OnCalendar',
            'interval' => '*-*-* 11:00:00',
        },
        logging_enabled           => false,
        user                      => 'eventlogcleaner',
        monitoring_contact_groups => 'analytics',
        require                   => [
            File['/usr/local/bin/eventlogging_cleaner'],
            File[$log_directory_path],
            File[$state_directory_path],
            User['eventlogcleaner'],
        ]
    }
}