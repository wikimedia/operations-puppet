# == Class profile::hadoop::backup::namenode
#
# Periodically runs hdfs dfsadmin -fetchImage
# and ensures that bacula backs up Hadoop NameNode fsimages,
# in the case we need to recover if both Hadoop NameNodes.
#
class profile::hadoop::backup::namenode(
    $monitoring_enabled = hiera('profile::hadoop::backup::namenode::monitoring_enabled', false),
    $use_kerberos       = hiera('profile::hadoop::backup::namenode::use_kerberos', false),
) {
    require ::profile::hadoop::common

    $backup_dir_group = $::realm ? {
        'production' => 'analytics-admins',
        'labs'       => "project-${::labsproject}",
    }

    if !defined(File['/srv/backup']) {
        file { '/srv/backup':
            ensure => 'directory',
            owner  => 'root',
            group  => $backup_dir_group,
            mode   => '0755',
        }
    }

    $destination = '/srv/backup/hadoop/namenode'
    file { [
            '/srv/backup/hadoop',
            $destination
        ]:
        ensure  => 'directory',
        owner   => 'hdfs',
        group   => $backup_dir_group,
        mode    => '0750',
        require => File['/srv/backup']
    }

    if $use_kerberos {
        $wrapper = '/usr/local/bin/kerberos-puppet-wrapper hdfs '
    } else {
        $wrapper = ''
    }

    cron { 'hadoop-namenode-backup-fetchimage':
        command => "${wrapper}/usr/bin/hdfs dfsadmin -fetchImage ${destination} > /dev/null 2>&1 ",
        user    => 'hdfs',
        hour    => 0,
        minute  => 0,
    }

    $retention_days = 30
    # Delete files older than $retention_days.
    cron { 'hadoop-namenode-backup-prune':
        command => "/usr/bin/find ${destination} -mtime +${retention_days} -delete > /dev/null 2>&1",
        user    => 'hdfs',
        hour    => 1,
        minute  => 0,
    }

    if !defined(Sudo::User['nagios_check_newest_file_age']) {
        sudo::user { 'nagios_check_newest_file_age':
            user       => 'nagios',
            privileges => ['ALL = NOPASSWD: /usr/local/lib/nagios/plugins/check_newest_file_age'],
        }
    }

    if $monitoring_enabled {
        # Alert if backup gets stale.
        $warning_threshold_hours = 26
        $critical_threshold_hours = 48
        nrpe::monitor_service { 'hadoop-namenode-backup-age':
            description   => 'Age of most recent Hadoop NameNode backup files',
            nrpe_command  => "/usr/bin/sudo /usr/local/lib/nagios/plugins/check_newest_file_age -V -C -d ${destination} -w ${$warning_threshold_hours} -c ${critical_threshold_hours}",
            contact_group => 'analytics',
            notes_url     => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/Cluster/Hadoop/Administration',
        }
    }

    # Bacula will also back up this directory.
    # See: bacula::director::fileset { 'hadoop-namenode-backup'
    # in profile::backup::director
    include ::profile::backup::host
    backup::set { 'hadoop-namenode-backup' : }
}
