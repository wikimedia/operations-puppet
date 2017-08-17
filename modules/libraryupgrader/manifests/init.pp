# = Class: role::libraryupgrader
#
# This class sets up a the Cloud VPS project libraryupgrader.
#
class libraryupgrader(
    $base_dir = '/srv'
){
    $clone_dir    = "${base_dir}/libraryupgrader"

    user { 'libraryupgrader':
        ensure => present,
        system => true,
    }

    file { '/home/libraryupgrader':
        ensure  => directory,
        owner   => 'libraryupgrader',
        require => User['libraryupgrader'],
    }

    file { [$clone_dir]:
        ensure => directory,
        owner  => 'extdist',
        group  => 'www-data',
        mode   => '0755',
    }

    git::clone {'labs/libraryupgrader':
        ensure    => latest,
        directory => $clone_dir,
        branch    => 'master',
        require   => [File[$clone_dir], User['extdist']],
        owner     => 'libraryupgrader',
        group     => 'libraryupgrader',
    }

    package { 'docker-engine':
        ensure => present,
    }

    package { 'apache2':
        ensure => present,
    }

    package { 'python3-jinja2':
        ensure => present,
    }

    cron { 'libraryupgrader-build':
        command => "/bin/bash ${clone_dir}/build.sh",
        user    => 'root',
        minute  => '0',
        hour    => '0',
        require => [
            Git::Clone['labs/libraryupgrader'],
            Package['docker-engine'],
        ],
    }

    cron { 'libraryupgrader-run':
        command => "/usr/bin/python3 ${clone_dir}/run.py",
        user    => 'root',
        minute  => '0',
        hour    => '1',
        require => [
            Git::Clone['labs/libraryupgrader'],
            Package['python3-jinja2'],
            Package['apache2'],
        ],
    }
}
