# Class: role::archiva
#
# Installs Apache Archiva and
# sets up a cron job to symlink .jar files to
# a git-fat store.
#
class role::archiva {
    system::role { 'role::archiva': description => 'Apache Archiva Host' }

    include ::base::firewall

    require_package('openjdk-7-jdk')

    class { '::archiva':
        require => Package['openjdk-7-jdk'],
    }

    # Set up a reverse proxy for the archiva service.
    class { '::archiva::proxy': }

    class { '::archiva::gitfat': }

    # Bacula backups for /var/lib/archiva.
    if $::realm == 'production' {
        include ::role::backup::host
        backup::set { 'var-lib-archiva':
            require => Class['::archiva']
        }
    }

    ferm::service { 'archiva_rsync':
        proto => 'tcp',
        port  => '873',
    }

    ferm::service { 'archiva_https':
        proto => 'tcp',
        port  => 443,
    }

    ferm::service { 'archiva_http':
        proto => 'tcp',
        port  => 80,
    }

    monitoring::service { 'https_archiva':
        description   => 'HTTPS',
        check_command => 'check_ssl_http_letsencrypt!archiva.wikimedia.org',
    }
}

