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

    group { 'eventlog':
        ensure => 'present',
        system => true,
    }

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

    file { '/etc/eventlogging':
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { '/etc/eventlogging/whitelist.tsv':
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///modules/profile/mariadb/misc/eventlogging/eventlogging_purging_whitelist.tsv',
        require => File['/etc/eventlogging'],
    }

    file { '/usr/local/bin/eventlogging_sync.sh':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0500',
        source => 'puppet:///modules/profile/mariadb/misc/eventlogging/eventlogging_sync.sh',
    }

    logrotate::rule { 'eventlogging':
        ensure        => present,
        file_glob     => '/var/log/eventlogging_*.log',
        frequency     => 'daily',
        copy_truncate => true,
        compress      => true,
        missing_ok    => true,
        not_if_empty  => true,
        rotate        => 14,
    }

    # Custom init scripts only that should be deprecated as soon as
    # the profile will run on Debian OS only.
    # The init script manages stdout/stderr to two separate files,
    # meanwhile the systemd unit used below will use a rsyslog dedicated config.
    if os_version('ubuntu >= trusty') {
        file { '/etc/init.d/eventlogging_sync':
            owner   => 'root',
            group   => 'root',
            mode    => '0555',
            content => template('profile/initscripts/mariadb/misc/eventlogging/eventlogging_sync.sysvinit.erb'),
            require => File['/usr/local/bin/eventlogging_sync.sh'],
            notify  => Service['eventlogging_sync'],
        }

        service { 'eventlogging_sync':
            ensure => running,
            enable => true,
        }
    } else {
        rsyslog::conf { 'eventlogging_sync':
            source   => 'puppet:///modules/profile/mariadb/misc/eventlogging/eventlogging_sync_rsyslog.conf',
            priority => 20,
        }

        $eventlogging_sync_uid = 'root'
        $eventlogging_sync_gid = 'root'
        base::service_unit { 'eventlogging_sync':
            ensure  => present,
            systemd => systemd_template('mariadb/misc/eventlogging/eventlogging_sync'),
        }

        # Sanitization of data in the log database via a custom script
        # The eventlogging_cleaner script uses the --start-ts-file file option,
        # that forces it to look for a file containing a timestamp in the format
        # %Y%m%d%H%M%S. If the file is not existent, the script will fail gracefully
        # without doing any action to the db. This is useful to avoid gaps in
        # records sanitized if the script fails and does not commit a new timestamp.
        $eventlogging_cleaner_command = '/usr/local/bin/eventlogging_cleaner --whitelist /etc/eventlogging/whitelist.tsv --older-than 90 --start-ts-file /var/run/eventlogging_cleaner --batch-size 10000 --sleep-between-batches 2'
        $command = "/usr/bin/flock -n /var/lock/eventlogging_cleaner -c '${eventlogging_cleaner_command}' >> /var/log/eventlogging_cleaner.log"
        cron { 'eventlogging_cleaner daily sanitization':
            ensure   => present,
            command  => $command,
            user     => 'eventlogcleaner',
            hour     => 1,
            require  => [
                File['/usr/local/bin/eventlogging_cleaner'],
                File['/etc/eventlogging/whitelist.tsv'],
                User['eventlogcleaner'],
            ]
        }
    }

    nrpe::monitor_service { 'eventlogging_sync':
        description   => 'eventlogging_sync processes',
        nrpe_command  => '/usr/lib/nagios/plugins/check_procs -c 1:2 -u root -a "/bin/bash /usr/local/bin/eventlogging_sync.sh"',
        critical      => false,
        contact_group => 'admins', # show on icinga/irc only
    }
}