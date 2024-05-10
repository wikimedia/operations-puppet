# SPDX-License-Identifier: Apache-2.0
# == Class profile::hadoop::backup::namenode
#
# Periodically backup the HDFS FSImage locally, and optionnally on HDFS.
# Also ensures that bacula backs up Hadoop NameNode fsimages,
# in the case we need to recover if both Hadoop NameNodes.
#
# @param monitoring_enabled [Boolean] Alerts in case of staling backup.
# @param fsimage_retention_days [Integer] Number of days during which the backups are kept.
# @param hdfs_backup_dir [String] HDFS directory to send the backup to. If present, it will add a systemd timer.
class profile::hadoop::backup::namenode(
    Boolean $monitoring_enabled       = lookup('profile::hadoop::backup::namenode::monitoring_enabled', {default_value => false}),
    Integer $fsimage_retention_days   = lookup('profile::hadoop::backup::namenode::fsimage_retention_days', {default_value => 10}),
    Optional[String] $hdfs_backup_dir = lookup('profile::hadoop::backup::namenode::hdfs_backup_dir', {default_value => undef}),
) {
    require ::profile::hadoop::common

    $backup_dir_group = $::realm ? {
        'production' => 'analytics-admins',
        'labs'       => "project-${::wmcs_project}",
    }

    if !defined(File['/srv/backup']) {
        file { '/srv/backup':
            ensure  => 'directory',
            owner   => 'root',
            group   => $backup_dir_group,
            mode    => '0755',
            require => Group[$backup_dir_group],
        }
    }

    $backup_dir = '/srv/backup/hadoop/namenode'
    file { [
            '/srv/backup/hadoop',
            $backup_dir
        ]:
        ensure  => 'directory',
        owner   => 'hdfs',
        group   => $backup_dir_group,
        mode    => '0750',
        require => File['/srv/backup']
    }

    $backup_file_path_cmd = "${backup_dir}/fsimage_$(/usr/bin/date +%%Y-%%m-%%d)"  # %% is for escaping % in systemd syntax
    kerberos::systemd_timer { 'hadoop-namenode-backup-fetchimage':
        description => 'Downloads the most recent fsimage from the NameNode and saves it in the specified local directory.',
        command     => "/usr/bin/bash -c \"/usr/bin/hdfs dfsadmin -fetchImage ${backup_file_path_cmd} && /usr/bin/gzip ${backup_file_path_cmd}\"",
        interval    => '*-*-* 00:00:00',  # everyday at midnight
        user        => 'hdfs',
    }

    if $hdfs_backup_dir != undef {

        $backup_manager_script = '/etc/hadoop/hdfs_fsimage_backup_manager_script.sh'
        file { $backup_manager_script:
            ensure => present,
            owner  => 'hdfs',
            group  => 'hdfs',
            mode   => '0750',
            source => 'puppet:///modules/profile/hadoop/hdfs_fsimage_backup_manager.sh'
        }

        kerberos::systemd_timer { 'hadoop-namenode-backup-hdfs':
            description => 'Checks that the local backup has been created, and sends it to HDFS.',
            command     => "${backup_manager_script} ${backup_dir} ${hdfs_backup_dir}",
            interval    => 'Mon *-*-* 02:00:00',  #  2am on Monday
            user        => 'hdfs'
        }
    }

    systemd::timer::job { 'hadoop-namenode-backup-prune':
      description     => "Deletes namenode's fsimage backups in ${backup_dir} older than ${fsimage_retention_days} days.",
      command         => "/usr/bin/find ${backup_dir} -mtime +${fsimage_retention_days} -delete",
      interval        => {
          'start'    => 'OnCalendar',
          'interval' => '*-*-* 04:00:00',
      },
      logging_enabled => false,
      user            => 'hdfs',
      send_mail_to    => 'data-engineering-alerts@wikimedia.org',
    }

    if !defined(Sudo::User['nagios_check_newest_file_age']) {
        sudo::user { 'nagios_check_newest_file_age':
            ensure => absent,
        }
    }

    if $monitoring_enabled {
        # Alert if backup gets stale.
        $warning_threshold_hours = 26
        $critical_threshold_hours = 48
        nrpe::monitor_service { 'hadoop-namenode-backup-age':
            description   => 'Age of most recent Hadoop NameNode backup files',
            nrpe_command  => "/usr/local/lib/nagios/plugins/check_newest_file_age -V -C -d ${backup_dir} -w ${$warning_threshold_hours} -c ${critical_threshold_hours}",
            sudo_user     => 'root',
            contact_group => 'team-data-platform',
            notes_url     => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/Cluster/Hadoop/Alerts#HDFS_Namenode_backup_age',
        }
    }

    # Bacula will also back up this directory.
    # See: bacula::director::fileset { 'hadoop-namenode-backup'
    # in profile::backup::director
    include ::profile::backup::host
    backup::set { 'hadoop-namenode-backup' : }
}
