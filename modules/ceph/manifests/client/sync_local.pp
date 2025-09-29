# SPDX-License-Identifier: Apache-2.0
# Class: ceph::client::sync_local
#
# This class allows syncing from a remote s3 bucket to a local folder.
#
# Parameters
#    - $sync_interval
#        The interval at which the folder should be synced (systemd timer notation).
#    - $local_dir
#        The local folder which is synced, like /tmp/bucket
#    - $remote_bucket
#        The remote bucket which is synced, like s3://example-bucket
#    - $object_storage_host
#        The hostname for the object storage service, like apus.discovery.wmnet
#    - $object_storage_credentials
#        Credentials to access the object storage (access_key and secret_key)
#    - $s3cfg_file
#        Path to the s3cfg file, like /tmp/.s3cfg
#    - $owner
#        Owner of s3 credentials file and the local folder
    class ceph::client::sync_local (
    Stdlib::Unixpath            $local_dir ,
    Stdlib::ObjectStore::S3Uri  $remote_bucket,
    Stdlib::Fqdn                $object_storage_host ,
    Ceph::S3::Credential        $object_storage_credentials,
    Stdlib::Unixpath            $s3cfg_file,
    Wmflib::Ensure              $ensure              = present,
    Systemd::Timer::Schedule    $sync_interval       = {'start' => 'OnCalendar', 'interval' => '*-*-* 00:00:00'},
    String                      $owner               = 'root',
    ) {

    package { 's3cmd':
        ensure  => $ensure,
    }

    $ensure_dir = $ensure ? {
        present => 'directory',
        default => 'absent',
    }

    wmflib::dir::mkdir_p($local_dir, {
        ensure => $ensure_dir,
        owner  => $owner,
    })

    file { $s3cfg_file:
        ensure  => $ensure,
        owner   => $owner,
        group   => $owner,
        content => template('ceph/s3cfg.erb'),
    }

    # sync files with bucket
    # TODO: also support syncing from local_dir to remote_bucket
    $sync_cmd = "/usr/bin/s3cmd -c ${s3cfg_file} sync --delete-removed ${remote_bucket} ${local_dir} "
    systemd::timer::job { 's3-sync-bucket':
        ensure      => $ensure,
        user        => $owner,
        description => 'Sync local folder from a remote s3 bucket',
        command     => $sync_cmd,
        interval    => $sync_interval,
        require     => Package['s3cmd'],
    }
}
