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
    $extra_parameters = hiera('profile::mariadb::misc::eventlogging::sanitization::extra_parameters', '')
) {

    if !defined(Group['eventlog']) {
        group { 'eventlog':
            ensure => 'present',
            system => true,
        }
    }

    $etc_directory_path = '/etc/eventlogging_cleaner'
    $log_directory_path = '/var/log/eventlogging_cleaner'

    user { 'eventlogcleaner':
        gid        => 'eventlog',
        shell      => '/bin/false',
        home       => '/nonexistent',
        comment    => 'EventLogging cleaner user',
        system     => true,
        managehome => false,
        require    => Group['eventlog'],
    }

    require_package('python3-pymysql')

    file { '/usr/local/bin/eventlogging_cleaner':
        ensure  => present,
        owner   => 'eventlogcleaner',
        group   => 'eventlog',
        mode    => '0550',
        source  => 'puppet:///modules/profile/mariadb/misc/eventlogging/eventlogging_cleaner.py',
        require => Package['python3-pymysql'],
    }

    file { $etc_directory_path:
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { $log_directory_path:
        ensure => 'directory',
        owner  => 'root',
        group  => 'eventlog',
        mode   => '0775',
    }

    file { "${etc_directory_path}/whitelist.tsv":
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///modules/profile/mariadb/misc/eventlogging/eventlogging_purging_whitelist.tsv',
        require => File[$etc_directory_path],
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
    $eventlogging_cleaner_command = "/usr/local/bin/eventlogging_cleaner --whitelist ${etc_directory_path}/whitelist.tsv --older-than 90 --start-ts-file /var/run/eventlogging_cleaner --batch-size 10000 --sleep-between-batches 2 ${extra_parameters}"
    $command = "/usr/bin/flock --verbose -n /var/lock/eventlogging_cleaner ${eventlogging_cleaner_command} >> ${log_directory_path}/eventlogging_cleaner.log"
    cron { 'eventlogging_cleaner daily sanitization':
        ensure      => present,
        command     => $command,
        user        => 'eventlogcleaner',
        minute      => 0,
        hour        => 11,
        environment => 'MAILTO=analytics-alerts@wikimedia.org',
        require     => [
            File['/usr/local/bin/eventlogging_cleaner'],
            File["${etc_directory_path}/whitelist.tsv"],
            File[$log_directory_path],
            User['eventlogcleaner'],
        ]
    }
}