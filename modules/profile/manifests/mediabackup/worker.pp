# SPDX-License-Identifier: Apache-2.0
# mediabackup worker installs the software and sets up
# the schedule needed to trigger the generation and
# recovery of media (swift) backups for wikis.
class profile::mediabackup::worker (
    Enum['minio', 'versitygw'] $worker_type = lookup('profile::mediabackup::worker::worker_type'),
    Hash $mediabackup_config = lookup('mediabackup'),
){

    ensure_packages([
        'rclone',
        's3cmd',  # optional, but useful s3 command line util
    ])
    file { '/root/.s3cfg':
        ensure    => file,
        owner     => 'root',
        group     => 'root',
        mode      => '0750',
        show_diff => false,
        content   => template('profile/mediabackup/s3cfg.erb')
    }
    file { ['/root/.config', '/root/.config/rclone']:
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0750',
    }
    file { '/root/.config/rclone/rclone.conf':
        ensure    => file,
        owner     => 'root',
        group     => 'root',
        mode      => '0610',
        show_diff => false,
        content   => template('profile/mediabackup/rclone.conf.erb')
    }

    if $worker_type == 'versitygw' {
        class { 'versitygw::client': }
    } elsif $worker_type == 'minio' {

        # setup mc client server aliases for admin convenience
        file { '/root/.mc':
            ensure => directory,
            owner  => 'root',
            group  => 'root',
            mode   => '0750',
        }

        file { '/root/.mc/config.json':
            ensure    => present,
            owner     => 'root',
            group     => 'root',
            mode      => '0750',
            show_diff => false,
            content   => template('mediabackup/mc_config.json.erb'),
        }
    } else {
        die("worker_type ${worker_type} is not a recognized value")
    }

    # Setup the media backups worker in production.
    # Some of the static configuration used here should probably
    # be moved later to the db to allow for more dynamic
    # configuration.
    class { 'mediabackup::worker':
        sections              => $mediabackup_config['sections'],
        mw_db_user            => $mediabackup_config['mw_db_user'],
        mw_db_password        => $mediabackup_config['mw_db_password'],
        dblists_path          => $mediabackup_config['dblists_path'],
        mw_db_config_file     => $mediabackup_config['mw_db_config_file'],
        batchsize             => $mediabackup_config['batchsize'],
        db_config_file        => $mediabackup_config['db_config_file'],
        db_host               => $mediabackup_config['db_host'],
        db_port               => $mediabackup_config['db_port'],
        db_user               => $mediabackup_config['db_user'],
        db_password           => $mediabackup_config['db_password'],
        db_schema             => $mediabackup_config['db_schema'],
        encryption_key        => $mediabackup_config['encryption_key'],
        storage_root_user     => $mediabackup_config['storage_root_user'],
        storage_root_password => $mediabackup_config['storage_root_password'],
        storage_hosts         => $mediabackup_config['storage_hosts'],
        access_key            => $mediabackup_config['access_key'],
        secret_key            => $mediabackup_config['secret_key'],
        recovery_access_key   => $mediabackup_config['recovery_access_key'],
        recovery_secret_key   => $mediabackup_config['recovery_secret_key'],
    }
}
