# SPDX-License-Identifier: Apache-2.0
# Media backups worker: Install required packages and configures
# them.
# * sections: hash containing as keys the MediaWiki sections (as they appear on
#             dblists to backup) and as value, another hash with the host, the port,
#             and optionally, a dblist file name containing the list of wikis
# * mw_db_user: user used to authenticate to the mediawiki database (neads only
#               SELECT grants on the image, oldimage and filearchive tables)
# * mw_db_password: password used to authenticate to the mediawiki database
# * dblists_path: Absolute path of where the dblists can be found.
# * mw_db_config_file: Absolute path of where the config file for database
#                      connection to MediaWiki production dbs will be stored
# * batchsize: maximum number of rows (files) of metadata to be read into memory and
#              processed for both mw metadata and backups metadata
# * db_config_file: Absolute path of where the config file for database
#                   connection to the mediabackup metadata db will be stored
# * db_host: fqdn of the database used to write the media backups metadata backend
# * db_port: port of such database
# * db_user: user used to authenticate to the database (needs read/write grants)
# * db_password: password used to authenticate to the database
# * db_schema: name of the database inside the server where the data is read
#              from and written to
# * storage_hosts: list of hosts where the file backend runs, where the files
#                  will be finally stored
# * storage_port: Port where all storage nodes will be listening to (it may
#                 change in the future to a per-host configuration (socket)
#                 to allow for multiplexing with multiple services per host
# * encryption_key: String used for encryption and decryption of private files
#                   Can be an age secret key or an ssh file
# * storage_root_user: identifier to authenticate on the s3-compatible api for
#                      the admin account (all privileges)
# * storage_root_password: password to authenticate on the s3-compatible api for
#                          the admin user
# * access_key: identifier to authenticate on the s3-compatible api to store
#               the backup files (it has both read and write permissions)
# * secret_key: password to authenticate on the s3-compatible api for backing
#               up files
# * recovery_access_key: identifier to authenticate on the s3-compatible api to
#                        restore  the backup files (only has read and list
#                        permissions)
# * recovery_secret_key: password to authenticate on the s3-compatible api
#                        for recovering files
class mediabackup::worker (
    Hash[String, Hash[String, Any]] $sections,
    String                          $mw_db_user,
    String                          $mw_db_password,
    Stdlib::Unixpath                $dblists_path,
    Stdlib::Unixpath                $mw_db_config_file,
    Integer[1]                      $batchsize,
    Stdlib::Unixpath                $db_config_file,
    Stdlib::Fqdn                    $db_host,
    Stdlib::Port                    $db_port,
    String                          $db_user,
    String                          $db_password,
    Array[Stdlib::Fqdn]             $storage_hosts,
    Stdlib::Port                    $storage_port,
    String                          $encryption_key,
    String                          $storage_root_user,
    String                          $storage_root_password,
    String                          $access_key,
    String                          $secret_key,
    String                          $recovery_access_key,
    String                          $recovery_secret_key,
    String                          $db_schema = 'mediabackups',
) {
    ensure_packages([
        'mediabackups',
        'rclone',
        's3cmd',  # optional, but useful s3 command line util
    ])

    # user and group so we don't run anything as a privileged user
    systemd::sysuser { 'mediabackup':
        home_dir => '/srv/mediabackup',
    }

    # location of temporary storage to download and hash files before
    # sending it to its final location
    file { '/srv/mediabackup':
        ensure => directory,
        mode   => '0750',
        owner  => 'mediabackup',
        group  => 'mediabackup',
    }

    # backup execution configuration dir (including secrets)
    file { '/etc/mediabackup':
        ensure => directory,
        mode   => '0400',
        owner  => 'mediabackup',
        group  => 'mediabackup',
    }

    $mw_db_ssl_ca = '/etc/ssl/certs/wmf-ca-certificates.crt'
    # list of backup source dbs to read mediawiki image metadata
    file { '/etc/mediabackup/mw_db.conf':
        ensure  => present,
        mode    => '0400',
        owner   => 'mediabackup',
        group   => 'mediabackup',
        content => template('mediabackup/mw_db.conf.erb'),
        require => File['/etc/mediabackup'],
    }
    # private data (password) and mysql connection settings
    # (minus host and port)
    file { $mw_db_config_file:
        ensure    => present,
        mode      => '0400',
        owner     => 'mediabackup',
        group     => 'mediabackup',
        content   => template('mediabackup/mw_db.ini.erb'),
        show_diff => false,
        require   => File['/etc/mediabackup'],
    }

    $db_ssl_ca = '/etc/ssl/certs/wmf-ca-certificates.crt'
    # general config for the access to a rw db to write and coordinate
    # backup metadata
    file { '/etc/mediabackup/mediabackups_db.conf':
        ensure  => present,
        mode    => '0400',
        owner   => 'mediabackup',
        group   => 'mediabackup',
        content => template('mediabackup/mediabackups_db.conf.erb'),
        require => File['/etc/mediabackup'],
    }
    # private data (password) and mysql connection settings
    file { '/etc/mediabackup/mediabackups_db.ini':
        ensure    => present,
        mode      => '0400',
        owner     => 'mediabackup',
        group     => 'mediabackup',
        content   => template('mediabackup/mediabackups_db.ini.erb'),
        show_diff => false,
        require   => File['/etc/mediabackup'],
    }

    $tmpdir = '/srv/mediabackup'
    # configuration and credentials to access final storage (S3-compatible
    # cluster on the same dc) for writing (backup generation)
    file { '/etc/mediabackup/mediabackups_storage.conf':
        ensure    => present,
        mode      => '0400',
        owner     => 'mediabackup',
        group     => 'mediabackup',
        content   => template('mediabackup/mediabackups_storage.conf.erb'),
        show_diff => false,
        require   => [ File['/etc/mediabackup'], File['/srv/mediabackup'], ],
    }

    # identity file used for encryption with age
    file { '/etc/mediabackup/encryption.key':
        ensure    => present,
        mode      => '0400',
        owner     => 'mediabackup',
        group     => 'mediabackup',
        content   => $encryption_key,
        show_diff => false,
    }

    # extra read-only policy for the recovery account
    file { '/etc/mediabackup/readandlist.json':
        ensure => present,
        owner  => 'mediabackup',
        group  => 'mediabackup',
        mode   => '0444',
        source => 'puppet:///modules/mediabackup/readandlist.json',
    }
    # extra read and deletion policy for the deletion account
    # Temporarily applied to the read only account until a separate
    # account is created for it.
    file { '/etc/mediabackup/readlistanddelete.json':
        ensure => present,
        owner  => 'mediabackup',
        group  => 'mediabackup',
        mode   => '0444',
        source => 'puppet:///modules/mediabackup/readlistanddelete.json',
    }
    # configuration and credentials to access final storage (S3-compatible
    # cluster on the same dc) for reading and listing (backup recovery)
    file { '/etc/mediabackup/mediabackups_recovery.conf':
        ensure    => present,
        mode      => '0400',
        owner     => 'mediabackup',
        group     => 'mediabackup',
        content   => template('mediabackup/mediabackups_recovery.conf.erb'),
        show_diff => false,
        require   => [
            File['/etc/mediabackup'],
            File['/srv/mediabackup'],
            File['/etc/mediabackup/readandlist.json'],
        ],
    }

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

    git::clone { 'operations/mediawiki-config':
        ensure    => present,
        directory => '/srv/mediawiki-config',
        owner     => 'mediabackup',
        group     => 'mediabackup',
    }
}
