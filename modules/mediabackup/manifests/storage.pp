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

    File { "${config_dir}/ssl":
        ensure  => directory,
        mode    => '0400',
        owner   => 'minio-user',
        group   => 'minio-user',
        require => [ File[$config_dir], User['minio-user'], Group['minio-user'] ],
    }

    # Delete old cert and key (ca is puppet, we don't delete that!)
    File { ["${config_dir}/ssl/server.key", "${config_dir}/ssl/cert.pem"]:
        ensure => absent,
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
