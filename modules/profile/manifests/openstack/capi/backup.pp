# SPDX-License-Identifier: Apache-2.0
#
# Backup capi worker state for OpenStack Magnum.
#
# Our minimal k3s install uses sqlite instead of etcd
#  so backing things up is mostly just copying files.
#
# There is a very brief service interruption during
#  the backup which should not be noticeable to users.
#
# Expects a cinder volume mounted on /srv
#
class profile::openstack::capi::backup(
    Stdlib::Unixpath $backup_dir = lookup('profile::openstack::capi::backup::dir', {'default_value' => '/srv/backup/'}),
) {
    wmflib::dir::mkdir_p($backup_dir)

    file { '/usr/local/sbin/backup-capi':
        ensure => file,
        mode   => '0555',
        source => 'puppet:///modules/profile/openstack/base/capi/backup-capi.sh',
    }

    file { "${backup_dir}/README":
        ensure => file,
        mode   => '0555',
        source => 'puppet:///modules/profile/openstack/base/capi/backup-capi-readme.txt',
    }

    systemd::timer::job { 'backup-capi':
        ensure             => present,
        user               => 'root',
        description        => 'backup capi worker state',
        command            => "/usr/local/sbin/backup-capi ${backup_dir}",
        interval           => {'start' => 'OnUnitInactiveSec', 'interval' => '24h'},
        monitoring_enabled => true,
        logging_enabled    => true,
    }
}
