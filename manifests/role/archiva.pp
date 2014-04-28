# Class: role::archiva
#
# Installs Apache Archiva and
# sets up a cron job to symlink .jar files to
# a git-fat store.
#
class role::archiva {
    system::role { 'role::archiva': description => 'Apache Archiva Host' }

    if !defined(Package['openjdk-7-jdk']) {
        package { 'openjdk-7-jdk':
            ensure => 'installed',
        }
    }

    $archiva_port = 8080
    class { '::archiva':
        port    => $archiva_port,
        require => Package['openjdk-7-jdk'],
    }

    class { '::archiva::gitfat':
        require => Class['::archiva']
    }

    # Set up simple Nginx reverse proxy port 80 to port $archiva_port
    class { '::nginx':
        require => Class['::archiva'],
    }
    $listen     = 80
    $proxy_pass = "http://127.0.0.1:${archiva_port}/"
    # need large body size to allow for .jar deployment
    $server_properties = ['client_max_body_size 256M']
    nginx::site { 'archiva':
        content => template('nginx/sites/simple-proxy.erb'),
        require => Class['::nginx'],
    }

    # Bacula backups for /var/lib/archiva.
    if $::realm == 'production' {
        include backup::host
        backup::set { 'var-lib-archiva':
            require => Class['::archiva']
        }
    }

    ferm::service { 'http':
        proto => 'tcp',
        port  => '80',
    }

    ferm::service { 'rsync':
        proto => 'tcp',
        port  => '873',
    }

}
