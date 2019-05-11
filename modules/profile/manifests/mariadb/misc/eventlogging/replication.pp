# == Class profile::mariadb::misc::eventlogging::replication
#
# This profile is responsible to add the custom replication service for
# the Eventlogging database (assumed to be 'log' for historical reasons).
# It consists in a bash script executed regularly that runs a mysqldump on the
# master host, copies it on localhost and then runs it against the local database.
# This profile will also install the eventlogging_cleaner Python script,
# responsible to apply the Analytics' sanitization/purging rules.
#
# [*master_host*]
#   The host that runs the log database to be replicated.
#
# [*cutoff_days*]
#   Don't try to 'replicate' tables with no events more recent than this many days ago.
#
# [*batch_size*]
#   Replicate this many rows at a time.
#
class profile::mariadb::misc::eventlogging::replication (
    $master_host = hiera('profile::mariadb::misc::eventlogging::replication::master_host'),
    $cutoff_days = hiera('profile::mariadb::misc::eventlogging::replication::cutoff_days'),
    $batch_size  = hiera('profile::mariadb::misc::eventlogging::replication::batch_size'),
) {
    $slave_host  = 'localhost'
    $database    = 'log'

    if !defined(Group['eventlog']) {
        group { 'eventlog':
            ensure => 'present',
            system => true,
        }
    }

    require_package('python3-pymysql')

    file { '/etc/eventlogging_sync':
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    $log_directory_path = '/var/log/eventlogging_sync'

    file { $log_directory_path:
        ensure => 'directory',
        owner  => 'root',
        group  => 'eventlog',
        mode   => '0775',
    }

    file { '/usr/local/bin/eventlogging_sync.sh':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0500',
        source => 'puppet:///modules/profile/mariadb/misc/eventlogging/eventlogging_sync.sh',
    }

    logrotate::rule { 'eventlogging-sync':
        ensure        => present,
        file_glob     => "${log_directory_path}/eventlogging_sync.log",
        frequency     => 'daily',
        copy_truncate => true,
        compress      => true,
        missing_ok    => true,
        not_if_empty  => true,
        rotate        => 14,
        su            => 'root eventlog',
    }

    rsyslog::conf { 'eventlogging_sync':
        content  => template('profile/mariadb/misc/eventlogging/eventlogging_sync_rsyslog.conf.erb'),
        priority => 20,
    }

    $eventlogging_sync_uid = 'root'
    $eventlogging_sync_gid = 'root'
    base::service_unit { 'eventlogging_sync':
        ensure  => present,
        systemd => systemd_template('mariadb/misc/eventlogging/eventlogging_sync'),
    }

    nrpe::monitor_service { 'eventlogging_sync':
        description   => 'eventlogging_sync processes',
        nrpe_command  => '/usr/lib/nagios/plugins/check_procs -c 1:2 -u root -a "/bin/bash /usr/local/bin/eventlogging_sync.sh"',
        critical      => false,
        contact_group => 'admins', # show on icinga/irc only
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/EventLogging',
    }
}
