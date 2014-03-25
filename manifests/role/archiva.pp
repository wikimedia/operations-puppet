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
    # Set up simple Nginx proxy to proxy from port 80 to $archiva_port
    $listen     = 80
    $proxy_pass = "http://127.0.0.1:${archiva_port}/"
    class { '::nginx':
        require => Class['::archiva'],
    }
    nginx::site { 'archiva':
        content => template('nginx/sites/simple-proxy.erb'),
        require => Class['::nginx'],
    }
}