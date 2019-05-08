# == Class: routinator
#
# Install and configure Routinator

# Actions:
#     * Installs routinator
#     * Add routinator user and working dir
#     * Adds RIR's TALs
#     * Add routinator systemd service
#     * Open ACL for prometheus monitoring
#     * Add Icinga monitoring for routinator process
#
# === Parameters
#  [*rtr_port*]
#   Port on which the RPKI-to-router daemon listens
#  [*proxy*]
#   "hostname:port" of proxy for rsync (optional)

class routinator(
  Stdlib::Port::Unprivileged $rtr_port,
  Optional[String] $proxy,
  ){

    require_package('routinator', 'rsync')

    group { 'routinator':
        ensure  => present,
        require => Package['routinator'],
    }
    user { 'routinator':
        ensure     => present,
        gid        => 'routinator',
        home       => '/etc/routinator',
        managehome => true,
    }

# Using the same paths as the Debian packaging efforts:
# https://salsa.debian.org/md/routinator/tree/master/debian
    file {'/etc/routinator/tals':
        ensure  => directory,
        source  => 'puppet:///modules/routinator/tals/',
        owner   => 'routinator',
        group   => 'routinator',
        mode    => '0755',
        recurse => true,
        purge   => true,
    }

    file {'/var/lib/routinator':
        ensure => directory,
        owner  => 'routinator',
        group  => 'routinator',
        mode   => '0755',
    }

    file {'/var/lib/routinator/repository':
        ensure => directory,
        owner  => 'routinator',
        group  => 'routinator',
        mode   => '0755',
    }

    systemd::service { 'routinator':
        content        => template('routinator/routinator.service.erb'),
        require        => [ File['/etc/routinator/tals'], File['/var/lib/routinator/repository'] ],
        restart        => true,
        service_params => {
            ensure     => 'running', # lint:ignore:ensure_first_param
        },
    }

    nrpe::monitor_service { 'routinator-process':
        description  => 'Routinator process',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C routinator',
        notes_url    => 'https://wikitech.wikimedia.org/wiki/RPKI#Process',
    }
  }
