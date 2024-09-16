# SPDX-License-Identifier: Apache-2.0
# Create mydumper logical backups using the dump_shards.sh hosts
# of all production core (s*, x*) and misc (m*) hosts.
# Do that using a cron job on all backup hosts, all datacenters.
# Note this profile creates the backups, but does not send them
# to bacula or other long-term storage, that is handled by the
# dbbackups::bacula class.
#
# Arguments:
# * enabled:    A boolean value that, if false, removes the execution
#               of the systemd timer (defaulting to true for backwards
#               compatiblity)
# * calendar:   A string containing the systemd timer's execution
#               calendar definition (defaulting to
#               'Tue *-*-* 00:00:00' for backwards compatibility)
# * config:     Relative path where the template with the dbbackups
#               config is, by default, on:
#               profile/dbbackups/${::hostname}.cnf.erb
# * statistics: Relative path where the template with the mysql
#               ini file is on puppet. If not given, we assume
#               the backup will not be monitored and the file is not
#               created (used like that by Cloud team at some point).
# * stats_db:   Database used to configure the statistics file, which
#               will be used to connect to the right schema.
# * stats_ca:   CA certificate used to configure the statistics file, which
#               will be used to connect using TLS (and enforce it).
class profile::dbbackups::mydumper (
    Boolean $enabled  = lookup('profile::dbbackups::mydumper::enabled',
      {default_value => true}),
    String  $calendar = lookup('profile::dbbackups::mydumper::calendar',
      {default_value => 'Tue *-*-* 00:00:00'}),
    String  $config = lookup('profile::dbbackups::mydumper::config',
      {default_value => ''}),
    String  $statistics = lookup('profile::dbbackups::mydumper::statistics',
      {default_value => ''}),
    String  $stats_host = lookup('profile::dbbackups::mydumper::stats_host',
      {default_value => ''}),
    String  $stats_db = lookup('profile::dbbackups::mydumper::stats_db',
      {default_value => ''}),
    String  $stats_ca = lookup('profile::dbbackups::mydumper::stats_ca',
      {default_value => ''}),
) {

    include ::passwords::mysql::dump

    ensure_packages([
        'wmfbackups',  # we now install all software from debian package
        'mydumper',  # mydumper is only a soft dependency, explicitly install it
        'parallel',  # dependency of mini_loader.sh (in addition to a mysql client)
    ])

    group { 'dump':
        ensure => present,
        system => true,
    }

    user { 'dump':
        ensure     => present,
        gid        => 'dump',
        shell      => '/bin/false',
        home       => '/srv/backups',
        system     => true,
        managehome => false,
    }

    # provisional hack to allow for recovery of 10.6 data
    file { '/usr/bin/load_file.sh':
        ensure => present,
        group  => 'root',
        owner  => 'root',
        mode   => '0755',
        source => 'puppet:///modules/profile/dbbackups/load_file.sh',
    }

    file { '/usr/bin/mini_loader.sh':
        ensure => present,
        group  => 'root',
        owner  => 'root',
        mode   => '0755',
        source => 'puppet:///modules/profile/dbbackups/mini_loader.sh',
    }

    file { '/srv/backups':
        ensure => directory,
        owner  => 'dump',
        group  => 'dump',
        mode   => '0711', # o+x so we can mount and check /ongoing
    }

    file { '/srv/backups/dumps':
        ensure  => directory,
        owner   => 'dump',
        group   => 'dump',
        mode    => '0711', # o+x so we can mount and check /ongoing
        require => File['/srv/backups'],
    }

    file { ['/srv/backups/dumps/ongoing',
            '/srv/backups/dumps/latest',
            '/srv/backups/dumps/archive',
        ]:
        ensure  => directory,
        owner   => 'dump',
        group   => 'dump',
        mode    => '0600', # implicitly 0700 for dirs
        require => File['/srv/backups/dumps'],
    }

    $user = $passwords::mysql::dump::user
    $password = $passwords::mysql::dump::pass
    $stats_user = $passwords::mysql::dump::stats_user
    $stats_password = $passwords::mysql::dump::stats_pass
    if $config == '' {
        $template = "profile/dbbackups/${::hostname}.cnf.erb"
    } else {
        $template = $config
    }
    file { '/etc/wmfbackups/backups.cnf':
        ensure    => present,
        owner     => 'dump',
        group     => 'dump',
        mode      => '0400',
        show_diff => false,
        content   => template($template),
    }

    # ensure old statistics file is deleted
    file { '/etc/wmfbackups/statistics.cnf':
        ensure => absent
    }
    if $statistics == '' {
        file { '/etc/wmfbackups/statistics.ini':
            ensure => absent
        }
    } else {
        # separate file for common statistics db config
        file { '/etc/wmfbackups/statistics.ini':
            ensure    => present,
            owner     => 'dump',
            group     => 'dump',
            mode      => '0400',
            show_diff => false,
            content   => template($statistics),
        }
    }

    # Logging support
    file { '/var/log/mariadb-backups':
        ensure => directory,
        owner  => 'dump',
        group  => 'dump',
        mode   => '0740',
    }

    if ($enabled) {
        $ensure = 'present'
    } else {
        $ensure = 'absent'
    }

    systemd::timer::job { 'dumps-sections':
        ensure        => $ensure,
        description   => 'MariaDB backups',
        command       => '/usr/bin/backup-mariadb --config-file=/etc/wmfbackups/backups.cnf',
        user          => 'dump',
        interval      => { 'start' => 'OnCalendar', 'interval' => $calendar},
        # Ignore any errors to avoid triggering Icinga alerts
        # if one or several of the backups fail.
        # Backup status notifications are handled in the backup check script.
        # Once 820664 has been merged, we will remove ignore_errors,
        # to ensure that we're notified about any other potential errors.
        ignore_errors => true,
    }

    class { 'toil::systemd_scope_cleanup': }  # T265323
}
