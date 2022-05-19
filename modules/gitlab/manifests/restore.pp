# SPDX-License-Identifier: Apache-2.0
# install restore script on secondary gitlab host
class gitlab::restore(
    Wmflib::Ensure           $ensure_restore_script = 'present',
    Wmflib::Ensure           $ensure_restore        = 'absent',
    Stdlib::Unixpath         $restore_dir_data      = '/srv/gitlab-backup',
    Systemd::Timer::Schedule $restore_interval      =  {'start' => 'OnCalendar', 'interval' => '*-*-* 01:30:00'},
){

    file {"${restore_dir_data}/gitlab-restore.sh":
        ensure => $ensure_restore_script,
        mode   => '0744' ,
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/gitlab/gitlab-restore.sh';
    }

    file {"${restore_dir_data}/gitlab-restore-v2.sh":
        ensure => $ensure_restore_script,
        mode   => '0744' ,
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/gitlab/gitlab-restore-v2.sh';
    }

    systemd::timer::job { 'backup-restore':
        ensure      => $ensure_restore,
        user        => 'root',
        description => 'GitLab Backup Restore',
        command     => "${restore_dir_data}/gitlab-restore.sh",
        interval    => $restore_interval,
    }
}
