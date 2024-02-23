# SPDX-License-Identifier: Apache-2.0
#
# Backup cinder volumes. This profile is expected to be included alongside
#  profile::wmcs::backy2 which installs necessary scripts and packages.
#
class profile::wmcs::backup_cinder_volumes(
    String               $cluster_name     = lookup('profile::wmcs::backy2::cluster_name'),
    Stdlib::Unixpath     $data_dir         = lookup('profile::cloudceph::data_dir'),
    String               $ceph_volume_pool = lookup('profile::openstack::eqiad1::cinder::ceph_pool'),
    String               $backup_interval  = lookup('profile::wmcs::backy2::volume_backup_time'),
    String               $cleanup_interval = lookup('profile::wmcs::backy2::volume_cleanup_time'),
    Boolean              $enabled          = lookup('profile::wmcs::backy2::backup_cinder_volumes::enabled'),
) {
    require profile::cloudceph::auth::deploy
    require profile::openstack::eqiad1::clientpackages

    if ! defined(Ceph::Auth::Keyring['admin']) {
        notify{'profile::wmcs::backup_glance_images: Admin keyring not defined, things might not work as expected.': }
    }

    file { '/etc/wmcs_backup_volumes.yaml':
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template('profile/wmcs/backy2/wmcs_backup_volumes.yaml.erb');
    }

    $timers_ensure = $enabled ? {
      true  => present,
      false => absent,
    }

    systemd::timer::job { 'backup_cinder_volumes':
        ensure          => $timers_ensure,
        description     => 'backup cinder volumes',
        exec_start_pre  => '/usr/local/sbin/wmcs-backup volumes delete-expired',
        command         => '/usr/local/sbin/wmcs-backup volumes backup-assigned-volumes',
        interval        => {
          'start'    => 'OnCalendar',
          'interval' => $backup_interval,
        },
        logging_enabled => true,
        user            => 'root',
        require         => File['/usr/local/sbin/wmcs-backup'],
    }

    systemd::timer::job { 'remove_dangling_cinder_snapshots':
        ensure          => $timers_ensure,
        description     => 'backup cinder volumes',
        exec_start_pre  => '/usr/local/sbin/wmcs-backup volumes remove-unhandled-backups',
        command         => '/usr/local/sbin/wmcs-backup volumes remove-dangling-snapshots',
        interval        => {
          'start'    => 'OnCalendar',
          'interval' => $cleanup_interval,
        },
        logging_enabled => true,
        user            => 'root',
        require         => File['/usr/local/sbin/wmcs-backup'],
    }
}
