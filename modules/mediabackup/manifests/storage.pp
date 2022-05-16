# SPDX-License-Identifier: Apache-2.0
# Media backups storage: Install required packages and configures
# them.
#
# * storage_path: the absolute path for the directory that will be
#                 used for storage of files, as configured by minio
# * port: the TCP port number where minio will be listening from
# * root_user: the string containing the admin user name
# * root_password: the string containing the admin authentication
#                  string.
# * config_dir: (deprecated) The location of the main config directory.
#               Minio now always stores config in a storage_path subdir.
class mediabackup::storage (
    Stdlib::Unixpath $storage_path,
    Stdlib::Port $port,
    String $root_user,
    String $root_password,
    Optional[Stdlib::Unixpath] $cert_path,
    Optional[Stdlib::Unixpath] $key_path,
    Optional[Stdlib::Unixpath] $ca_path,
    Stdlib::Unixpath $config_dir = '/etc/minio',
) {
    ensure_packages(['minio', ])

    systemd::sysuser { 'minio-user':
        home_dir => $storage_path,
    }

    file { $storage_path:
        ensure  => directory,
        mode    => '0750',
        owner   => 'minio-user',
        group   => 'minio-user',
        require => User['minio-user'],
    }
    # Please note that config dir option is deprecated:
    # https://docs.min.io/docs/minio-server-configuration-guide.html
    file { $config_dir:
        ensure  => directory,
        mode    => '0440',
        owner   => 'minio-user',
        group   => 'minio-user',
        require => User['minio-user'],
    }

    file { "${config_dir}/ssl":
        ensure  => directory,
        mode    => '0700',
        owner   => 'minio-user',
        group   => 'minio-user',
        require => [ File[$config_dir], User['minio-user'] ],
    }

    file { "${storage_path}/.minio":
        ensure  => directory,
        mode    => '0700',
        owner   => 'minio-user',
        group   => 'minio-user',
        require => File[$storage_path],
    }
    file { "${storage_path}/.minio/certs":
        ensure  => directory,
        mode    => '0600',
        owner   => 'minio-user',
        group   => 'minio-user',
        require => File["${storage_path}/.minio"],
    }

    # file names are hardcoded, so using symlinks to expose them
    if $key_path {
        file { "${storage_path}/.minio/certs/private.key":
            ensure => 'link',
            target => $key_path,
            owner  => 'minio-user',
            group  => 'minio-user',
        }
    }
    if $cert_path {
        file { "${storage_path}/.minio/certs/public.crt":
            ensure => 'link',
            target => $cert_path,
            owner  => 'minio-user',
            group  => 'minio-user',
        }
    }

    file { '/etc/default/minio':
        ensure    => present,
        mode      => '0440',
        owner     => 'minio-user',
        group     => 'minio-user',
        content   => template('mediabackup/default_minio.erb'),
        show_diff => false,
        require   => User['minio-user'],
    }

    service { 'minio':
        ensure  => running,
        enable  => true,
        require => [ Package['minio'], File['/etc/default/minio'] ],
    }
}
