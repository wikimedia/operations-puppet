# SPDX-License-Identifier: Apache-2.0
# == Class profile::ceph::backup::s3_local
#
# This class can be used to create local backup copies of remote S3 buckets.
# It is intended to be used to create a backup of any vital files that are saved
# to the cephosd clusters, such as PostgreSQL dumps.
#
# @param [WMFlib::Ensure] ensure
#     present/absent to install/remove config/timer
# @param [Stdlib::Unixpath] backup_dir
#     This is the directory which will contain the backups and config
# @param Hash[String,Hash[String,String]] sources
#     The required data structure is:
#       bucket_name_1:
#         access_key: foo
#         secret_key: bar
#       bucket_name_2:
#         access_key: baz
#         secret_key: foobarbaz

class profile::ceph::backup::s3_local (
    WMFlib::Ensure                   $ensure     = lookup('profile::ceph::backup::s3_local:ensure',default_value => absent),
    Stdlib::Unixpath                 $backup_dir = lookup('profile::ceph::backup::s3_local:ensure',default_value => '/srv/postgresql_backups'),
    Hash[String,Hash[String,String]] $sources    = lookup('profile::ceph::backup::s3_local:sources',default_value => {}),
) {
    ensure_packages('rclone')

    file { $backup_dir:
        ensure => directory,
        owner  => 'backup',
        group  => 'backup',
        mode   => '0600',
    }
    file { "${backup_dir}/rclone.conf":
        ensure  => $ensure,
        owner   => 'backup',
        group   => 'backup',
        mode    => '0600',
        content => epp ('profile/ceph/backup/s3_local/rclone.conf.epp', {
            sources => $sources,
        }),
    }
}
