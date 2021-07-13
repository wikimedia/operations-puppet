# Media backups storage: Install required packages and configures
# them.
#
# * storage_path: the absolute path for the directory that will be
#                 used for storage of files, as configured by minio
# * port: the TCP port number where minio will be listening from
# * config_dir: The location of the main config directory and where
#               TLS certs will be located
class mediabackup::storage (
    Stdlib::Unixpath $storage_path,
    Stdlib::Port $port,
    Stdlib::Unixpath $config_dir = '/etc/minio',
) {
    ensure_packages(['minio', ])

    group { 'minio-user':
        ensure => present,
        system => true,
    }

    user { 'minio-user':
        ensure     => present,
        gid        => 'minio',
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
    File { "${config_dir}/certs":
        ensure  => directory,
        mode    => '0440',
        owner   => 'minio-user',
        group   => 'minio-user',
        require => File[$config_dir],
    }
    # file names are hardcoded, only cert-dir can be configured
    file { "${config_dir}/certs/private.key":
        ensure  => 'link',
        target  => '${config_dir}/ssl/server.key',
        owner   => 'minio-user',
        group   => 'minio-user',
        require => Base::Expose_puppet_certs[$config_dir],
    }
    file { "${config_dir}/certs/public.crt":
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
