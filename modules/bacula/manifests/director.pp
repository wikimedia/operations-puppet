# Class: bacula::director
#
# This class installs bacula-dir, configures it and ensures that it is running
#
# Parameters:
#   $sqlvariant
#       mysql, pgsql, sqlite3
#   $max_dir_concur_jobs
#       The maximum number of jobs this director will allow running at the same
#       time. This means it is a hard limit on the number of what the entire
#       infrastructure will do and should be tuned appropriately
#   $dir_port
#       The port the director listens on. Default 9101
#
# Actions:
#       Install bacula-dir, configure, ensure running
#
# Requires:
#
# Sample Usage:
#       class { 'bacula::director':
#           sqlvariant              => 'mysql',
#           max_dir_concur_jobs     => '10',
#       }
#
class bacula::director(
                    $sqlvariant,
                    $max_dir_concur_jobs,
                    $dir_port='9101',
                    $bconsolepassword=sha1($::uniqueid)) {
    # bacula-director depends on bacula-director-sqlvariant
    package { "bacula-director-${sqlvariant}":
        ensure    => installed,
    }

    service { 'bacula-director':
        ensure  => running,
        # The init script bacula-director, the process bacula-dir
        pattern => 'bacula-dir',
        restart => '/usr/sbin/invoke-rc.d bacula-director reload',
        require => Package["bacula-director-${sqlvariant}"],
    }

    File <<| tag == "bacula-client-${::fqdn}" |>>
    File <<| tag == "bacula-storage-${::fqdn}" |>>

    # Puppet manages the permissions of its private key file and they are too
    # restrictive to allow any other user/group to read it. Copy it, keep it in
    # sync and set the require permissions for bacula-dir to be able to read it
    exec { 'bacula_cp_private_key':
        command => "/bin/cp /var/lib/puppet/ssl/private_keys/${::fqdn}.pem \
 /var/lib/puppet/ssl/private_keys/bacula-${::fqdn}.pem",
        unless  => "/usr/bin/cmp /var/lib/puppet/ssl/private_keys/${::fqdn}.pem \
 /var/lib/puppet/ssl/private_keys/bacula-${::fqdn}.pem",
    }

    file { "/var/lib/puppet/ssl/private_keys/bacula-${::fqdn}.pem":
        ensure  => present,
        owner   => 'bacula',
        group   => 'bacula',
        mode    => '0400',
        require => Exec['bacula_cp_private_key'],
        notify  => Service['bacula-director'],
    }

    file { '/etc/bacula/bacula-dir.conf':
        ensure  => present,
        owner   => root,
        group   => bacula,
        mode    => '0440',
        notify  => Service['bacula-director'],
        content => template('bacula/bacula-dir.conf.erb'),
        require => Package["bacula-director-${sqlvariant}"],
    }

    # We will include this dir and all general options will be here
    file { '/etc/bacula/conf.d':
        ensure  => directory,
        recurse => true,
        force   => true,
        purge   => true,
        mode    => '0444',
        owner   => root,
        group   => bacula,
        require => Package["bacula-director-${sqlvariant}"],
    }

    # Clients will export their resources here
    file { '/etc/bacula/clients.d':
        ensure  => directory,
        recurse => true,
        force   => true,
        purge   => true,
        mode    => '0444',
        owner   => root,
        group   => bacula,
        require => Package["bacula-director-${sqlvariant}"],
    }

    file { '/etc/bacula/jobs.d':
        ensure  => directory,
        recurse => true,
        force   => true,
        purge   => true,
        mode    => '0444',
        owner   => root,
        group   => bacula,
        require => Package["bacula-director-${sqlvariant}"],
    }

    # Populating restore template/migrate jobs
    file { '/etc/bacula/jobs.d/restore-migrate-jobs.conf':
        ensure  => file,
        mode    => '0444',
        owner   => root,
        group   => bacula,
        require => File['/etc/bacula/jobs.d'],
        content => template('bacula/restore-migrate-jobs.conf.erb'),
    }

    # Storage daemons will export their resources here
    file { '/etc/bacula/storages.d':
        ensure  => directory,
        recurse => true,
        force   => true,
        purge   => true,
        mode    => '0444',
        owner   => root,
        group   => bacula,
        require => Package["bacula-director-${sqlvariant}"],
    }

    # Exporting configuration for console users
    @@file { '/etc/bacula/bconsole.conf':
        ensure  => present,
        mode    => '0440',
        owner   => root,
        group   => bacula,
        content => template('bacula/bconsole.conf.erb'),
        tag     => "bacula-console-${::fqdn}",
    }
}
