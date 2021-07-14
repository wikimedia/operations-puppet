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
    Stdlib::Unixpath $config_dir = '/etc/minio',
) {
    ensure_packages(['minio', ])

    group { 'minio-user':
        ensure => present,
        system => true,
    }

    user { 'minio-user':
        ensure     => present,
        gid        => 'minio-user',
        shell      => '/bin/false',
        home       => $storage_path,
        system     => true,
        managehome => false,
        require    => Group['minio-user'],
    }

    File { $storage_path:
        ensure  => directory,
        mode    => '0750',
        owner   => 'minio-user',
        group   => 'minio-user',
        require => [ User['minio-user'], Group['minio-user'] ],
    }
    # Please note that config dir option is deprecated:
    # https://docs.min.io/docs/minio-server-configuration-guide.html
    File { $config_dir:
        ensure  => directory,
        mode    => '0440',
        owner   => 'minio-user',
        group   => 'minio-user',
        require => [ User['minio-user'], Group['minio-user'] ],
    }

    # TLS certs handling (using Puppet ones for now)
    base::expose_puppet_certs { $config_dir:
        ensure          => present,
        provide_private => true,
        user            => 'minio-user',
        group           => 'minio-user',
        require         => [ File[$config_dir], User['minio-user'], Group['minio-user'] ],
    }
    File { "${storage_path}/.minio":
        ensure  => directory,
        mode    => '0700',
        owner   => 'minio-user',
        group   => 'minio-user',
        require => File[$storage_path],
    }
    File { "${storage_path}/.minio/certs":
        ensure  => directory,
        mode    => '0600',
        owner   => 'minio-user',
        group   => 'minio-user',
        require => File["${storage_path}/.minio"],
    }

    # TODO: Remove the next 3 resources, as they will be linked elsewere
    file { "${config_dir}/certs/private.key":
        ensure  => absent,
    }
    file { "${config_dir}/certs/public.crt":
        ensure  => absent,
    }
    File { "${config_dir}/certs":
        ensure  => absent,
        require => [ File["${config_dir}/certs/private.key"], File["${config_dir}/certs/public.crt"], ],
    }

    # file names are hardcoded, so using symlinks to expose them
    file { "${storage_path}/.minio/certs/private.key":
        ensure  => 'link',
        target  => '${config_dir}/ssl/server.key',
        owner   => 'minio-user',
        group   => 'minio-user',
        require => Base::Expose_puppet_certs[$config_dir],
    }
    file { "${storage_path}/.minio/certs/public.crt":
        ensure  => 'link',
        target  => '${config_dir}/ssl/cert.pem',
        owner   => 'minio-user',
        group   => 'minio-user',
        require => Base::Expose_puppet_certs[$config_dir],
    }

    File { '/etc/default/minio':
        ensure  => present,
        mode    => '0440',
        owner   => 'minio-user',
        group   => 'minio-user',
        content => template('mediabackup/default_minio.erb'),
        require => [ User['minio-user'], Group['minio-user'] ],
    }

    service { 'minio':
        ensure  => running,
        enable  => true,
        require => [ Package['minio'], File['/etc/default/minio'] ],
    }
}
