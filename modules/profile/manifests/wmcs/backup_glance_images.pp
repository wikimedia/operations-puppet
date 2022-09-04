# SPDX-License-Identifier: Apache-2.0
#
# Backup glance images. This profile is expected to be included alongside
#  profile::wmcs::backy2 which installs necessary scripts and packages.
#
class profile::wmcs::backup_glance_images(
    String               $cluster_name    = lookup('profile::wmcs::backy2::cluster_name'),
    Stdlib::Unixpath     $data_dir        = lookup('profile::ceph::data_dir'),
    String               $ceph_image_pool = lookup('profile::ceph::client::rbd::glance::pool'),
    String               $backup_interval = lookup('profile::wmcs::backy2::image_backup_time'),
    Boolean              $enabled         = lookup('profile::wmcs::backy2::backup_glance_images::enabled'),
) {
    require profile::ceph::auth::deploy
    if ! defined(Ceph::Auth::Keyring['admin']) {
        notify{'profile::wmcs::backup_glance_images: Admin keyring not defined, things might not work as expected.': }
    }

    file { '/etc/wmcs_backup_images.yaml':
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template('profile/wmcs/backy2/wmcs_backup_images.yaml.erb');
    }

    $timers_ensure = $enabled ? {
      true  => present,
      false => absent,
    }

    systemd::timer::job { 'backup_glance_images':
        ensure                    => $timers_ensure,
        description               => 'backup images',
        command                   => '/usr/local/sbin/wmcs-backup images backup-all-images',
        interval                  => {
          'start'    => 'OnCalendar',
          'interval' => $backup_interval,
        },
        logging_enabled           => true,
        monitoring_enabled        => true,
        monitoring_contact_groups => 'wmcs-team-email',
        user                      => 'root',
        require                   => File['/usr/local/sbin/wmcs-backup'],
    }
}
