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

    class { '::archiva':
        require => Package['openjdk-7-jdk'],
    }

    # Set up a reverse proxy for the archiva service.
    class { '::archiva::proxy': }

    class { '::archiva::gitfat': }

    # Bacula backups for /var/lib/archiva.
    if $::realm == 'production' {
        include role::backup::host
        backup::set { 'var-lib-archiva':
            require => Class['::archiva']
        }
    }

    ferm::service { 'rsync':
        proto => 'tcp',
        port  => '873',
    }
}

