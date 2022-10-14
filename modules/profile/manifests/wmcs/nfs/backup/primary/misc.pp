# SPDX-License-Identifier: Apache-2.0
class profile::wmcs::nfs::backup::primary::misc (
    String $passive_server = lookup(
        'profile::wmcs::nfs::primary::passive_server',
        String,
        'first',
        'labstore1005.eqiad.wmnet'
    ),
    String $backup_interval = lookup(
        'profile::wmcs::nfs::primary_backup::misc::backup_interval',
    ),
){

    file { '/srv/backup/misc':
        ensure  => 'directory',
        require => File['/srv/backup'],
    }

    labstore::device_backup { 'primary-misc':
        remotehost          => $passive_server,
        remote_vg           => 'misc',
        remote_lv           => 'misc-project',
        remote_snapshot     => 'misc-snap',
        local_vg            => 'backup',
        local_lv            => 'misc-project',
        local_snapshot      => 'misc-project-backup',
        local_snapshot_size => '2T',
        interval            => $backup_interval,
    }

}
