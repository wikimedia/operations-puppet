# Class: bacula::storage
#
# This class installs bacula-sd, configures it and ensures that it is running
#
# Parameters:
#   $director
#       The FQDN of the server being our director
#   $sd_max_concur_jobs
#       The maxinum number of jobs this SD is allowd to run simultaneously
#   $sqlvariant
#       mysql, pgsql, sqlite3
#   $sd_port
#       If needed to change the port the sd listens on. Default 9103
#
# Actions:
#       Install bacula-sd, configure, ensure running
#       The director password is autogenerated and exported
#       Exports configuration to bacula-director
#
# Requires:
#
# Sample Usage:
#       class { 'bacula::storage':
#           director            => 'dir.example.com',
#           sd_max_concur_jobs  => 5,
#           sqlvariant          => 'mysql',
#       }
#
class bacula::storage(
    Stdlib::Host                      $director,
    Integer[0]                        $sd_max_concur_jobs,
    Enum['mysql', 'pgsql', 'sqlite3'] $sqlvariant,
    Stdlib::Port                      $sd_port = 9103,
    String                            $directorpassword=sha1($::uniqueid)
){
    ensure_packages(['bacula-sd', ])

    service { 'bacula-sd':
        ensure  => running,
        require => Package['bacula-sd'],
    }

    file { '/etc/bacula/sd':
        ensure  => directory,
        mode    => '0550',
        owner   => 'bacula',
        group   => 'tape',
        require => Package['bacula-sd'],
    }

    # TODO: consider using profile::pki::get_cert
    puppet::expose_agent_certs { '/etc/bacula/sd':
        provide_private => true,
        provide_keypair => true,
        user            => 'bacula',
        group           => 'bacula',
        require         => File['/etc/bacula/sd'],
    }

    file { '/etc/bacula/sd-devices.d':
        ensure  => directory,
        recurse => true,
        force   => true,
        purge   => true,
        mode    => '0550',
        owner   => 'bacula',
        group   => 'tape',
        require => File['/etc/bacula/bacula-sd.conf'],
    }

    file { '/etc/bacula/bacula-sd.conf':
        ensure  => present,
        owner   => 'bacula',
        group   => 'tape',
        mode    => '0400',
        notify  => Service['bacula-sd'],
        content => template('bacula/bacula-sd.conf.erb'),
        require => Package['bacula-sd'],
    }
}
