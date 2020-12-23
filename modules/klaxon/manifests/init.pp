# == Class: klaxon
#
# Install and configure klaxon, a simple webapp for users to page SRE.
class klaxon(
    Klaxon::Klaxon_config $config,
    Stdlib::Unixpath $install_dir = '/srv/klaxon',
    Stdlib::Port $port = 4667,
) {
    ensure_packages(['gunicorn', 'python3-cachetools', 'python3-dateutil', 'python3-flask', 'python3-requests'])

    $environ_file = '/var/lib/klaxon/environ_file'

    # TODO: a better deployment model.
    git::clone { 'operations/software/klaxon':
        directory => $install_dir,
        branch    => 'master',
    }

    group { 'klaxon':
        ensure => present,
        system => true,
    }

    user { 'klaxon':
        gid        => 'klaxon',
        shell      => '/bin/bash',
        system     => true,
        managehome => true,
        home       => '/var/lib/klaxon',
        require    => Group['klaxon'],
    }

    file { $environ_file:
        ensure  => 'file',
        owner   => 'root',
        group   => 'klaxon',
        mode    => '0440',
        require => User['klaxon'],
        content => template('klaxon/environ_file.erb'),
    }

    systemd::service { 'klaxon':
        ensure  => 'present',
        content => systemd_template('klaxon'),
        restart => true,
        require => [
          User['klaxon'],
          Git::Clone['operations/software/klaxon'],
          File[$environ_file],
        ],
    }
}
