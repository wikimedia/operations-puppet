# Class: profile::archiva
#
# Installs Apache Archiva and sets up a cron job to symlink .jar files to
# a git-fat store.
#
class profile::archiva(
    $enable_backup = hiera('profile::archiva::enable_backup', false),
) {
    require_package('default-jdk')

    class { '::archiva': }

    class { '::archiva::gitfat': }

    # Bacula backups for /var/lib/archiva.
    if $enable_backup {
        include ::profile::backup::host
        backup::set { 'var-lib-archiva':
            require => Class['::archiva']
        }
    }

    ferm::service { 'archiva_rsync':
        proto => 'tcp',
        port  => '873',
    }
}