# SPDX-License-Identifier: Apache-2.0
# @summary manage backup timers
class gitlab::backup (
    Wmflib::Ensure           $ensure                  = 'present',
    Wmflib::Ensure           $full_ensure             = 'present',
    Wmflib::Ensure           $partial_ensure          = 'present',
    Wmflib::Ensure           $config_ensure           = 'present',
    Boolean                  $rsyncable_gzip          = true,
    Integer[1]               $max_concurrency         = 4,
    Integer[1]               $max_storage_concurrency = 1,
    Integer[1]               $backup_keep_time        = 3,
    Stdlib::Unixpath         $backup_dir_data         = '/srv/gitlab-backup',
    Stdlib::Unixpath         $backup_dir_config       = '/etc/gitlab/config_backup',
    Systemd::Timer::Schedule $full_backup_interval    = {'start' => 'OnCalendar', 'interval' => '*-*-* 00:00:00'},
    Systemd::Timer::Schedule $config_backup_interval  = {'start' => 'OnCalendar', 'interval' => '*-*-* 00:00:00'},
    Systemd::Timer::Schedule $partial_backup_interval = {'start' => 'OnCalendar', 'interval' => '*-*-* 00:00:00'},
) {

    # install backup script
    file { "${backup_dir_data}/gitlab-backup.sh":
        ensure  => present,
        mode    => '0744',
        owner   => 'root',
        group   => 'root',
        content => template('gitlab/gitlab-backup.sh.erb') # TODO: remove, T254480
    }

    # systemd timer for full backups
    systemd::timer::job { 'full-backup':
        ensure      => $full_ensure,
        user        => 'root',
        description => 'GitLab full data backup',
        command     => "${backup_dir_data}/gitlab-backup.sh full",
        interval    => $full_backup_interval,
    }

    # systemd timer for partial backups
    systemd::timer::job { 'partial-backup':
        ensure      => $partial_ensure,
        user        => 'root',
        description => 'GitLab partial data backup',
        command     => "${backup_dir_data}/gitlab-backup.sh partial",
        interval    => $partial_backup_interval,
    }

    # systemd timer for config backups
    systemd::timer::job { 'config-backup':
        ensure      => $config_ensure,
        user        => 'root',
        description => 'GitLab config backup',
        command     => "${backup_dir_data}/gitlab-backup.sh config",
        interval    => $config_backup_interval,
    }

    # make sure git user can access backup folders
    # create folder for backups
    file { $backup_dir_data:
        ensure => directory,
        owner  => 'git',
        group  => 'root',
        mode   => '0600',
    }

    # make sure only root can access latest backup folders
    # create folder for latest backup
    file { ["${backup_dir_data}/latest", "${backup_dir_config}/latest"]:
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0600',
    }
}
