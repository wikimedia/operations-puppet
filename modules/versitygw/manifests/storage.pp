# SPDX-License-Identifier: Apache-2.0
# Versity S3 Gateway storage: Install required packages and configures
# them.
#
# * storage_path: the absolute path for the directory that will be
#                 used for storage of files, as configured by minio
# * port: the TCP port number where minio will be listening from
# * console_port: the TCP port number where the built-in browser-based
#                 web interface will be listening from. Useful for
#                 human friendly debugging (see:
# https://wikitech.wikimedia.org/wiki/Media_storage/Backups#How_to_access_the_web_UI_of_minio
# )
# * root_user: the string containing the admin user name
# * root_password: the string containing the admin authentication
#                  string.
# * config_dir: The location of the main config directory to create the instance
#               config. This module will assume it is already created.
define versitygw::storage (
    Stdlib::Unixpath $storage_path,
    Stdlib::Port $port,
    # Stdlib::Port $console_port,
    String $root_user,
    String $root_password,
    Optional[Stdlib::Unixpath] $cert_path,
    Optional[Stdlib::Unixpath] $key_path,
    Optional[Stdlib::Unixpath] $ca_path,
    String $unix_user = 'objectstorage',
    String $unix_group = 'objectstorage',
    Stdlib::Unixpath $home_dir = '/srv',
    Stdlib::Unixpath $config_dir = '/etc/versitygw',
) {
    file { $storage_path:
        ensure  => directory,
        mode    => '0750',
        owner   => $unix_user,
        group   => $unix_group,
        require => [ User[$unix_user]]
    }
    file { "${config_dir}/${title}.cfg":
        ensure  => file,
        mode    => '0700',
        owner   => $unix_user,
        group   => $unix_group,
        require => [ File[$config_dir], User[$unix_user]],
    }

    # The iam dir contains authetication information common to all services, and
    # shouldn't be readable to anyone except the service user.
    # For now it is handled as data to backup, not as config (puppet).
    $iam_dir = "${home_dir}/iam"
    file { "/etc/default/versitygw@${title}":
        ensure    => present,
        mode      => '0440',
        content   => template('versitygw/default_versitygw.erb'),
        show_diff => false,
    }

    systemd::service { "versitygw@${title}":
        ensure    => present,
        restart   => true,
        content   => systemd_template('versitygw'),
        require   => [
            # TODO: Skip until package built: Package['versitygw'],
            File["/etc/default/versitygw@${title}"]
        ],
        subscribe => [
            File["/etc/default/versitygw@${title}"],
            File[$cert_path],
        ],
    }
}
