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

class bacula::director($sqlvariant, $max_dir_concur_jobs, $dir_port='9101') {
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

    file { '/etc/bacula/bacula-dir.conf':
        ensure  => present,
        owner   => root,
        group   => root,
        mode    => '0600',
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
        mode    => '0755',
        owner   => root,
        group   => bacula,
        require => Package["bacula-director-${sqlvariant}"],
    }

    # Clients will export their resources here
    file { '/etc/bacula/clients.puppet.d':
        ensure  => directory,
        recurse => true,
        force   => true,
        purge   => true,
        mode    => '0755',
        owner   => root,
        group   => bacula,
        require => Package["bacula-director-${sqlvariant}"],
    }

    file { '/etc/bacula/jobs.puppet.d':
        ensure  => directory,
        recurse => true,
        force   => true,
        purge   => true,
        mode    => '0755',
        owner   => root,
        group   => bacula,
        require => Package["bacula-director-${sqlvariant}"],
    }

    # Storage daemons will export their resources here
    file { '/etc/bacula/storages.puppet.d':
        ensure  => directory,
        recurse => true,
        force   => true,
        purge   => true,
        mode    => '0755',
        owner   => root,
        group   => bacula,
        require => Package["bacula-director-${sqlvariant}"],
    }

    # Exporting configuration for console users
    $bconsolepassword = sha1($::uniqueid)
    @@file { '/etc/bacula/bconsole.conf':
        ensure  => present,
        mode    => '0640',
        owner   => root,
        group   => bacula,
        content => template('bacula/bconsole.conf.erb'),
        tag     => "bacula-console-${director}",
    }

}
