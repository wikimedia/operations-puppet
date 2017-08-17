# = Class: role::labs::libraryupgrader
#
# This class sets up a the Cloud VPS project libraryupgrader.
#
class role::labs::libraryupgrader(
    $clone_dir = '/srv/libraryupgrader'
){
    user { 'libraryupgrader':
        ensure => present,
        system => true,
    }

    file { '/home/libraryupgrader':
        ensure  => directory,
        owner   => 'libraryupgrader',
        require => User['libraryupgrader'],
    }

    file { $clone_dir:
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

    # Docker is called by run.py to handle sub-tasks
    package { 'docker-engine':
        ensure => present,
    }

    # Serve generated HTML files that are dumped
    # into /var/www/html
    package { 'apache2':
        ensure => present,
    }

    # Needed by run.py to generate HTML files
    package { 'python3-jinja2':
        ensure => present,
    }

    # Build a new docker image, every day at midnight
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

    # Run the main test script, every day at 1:00 UTC
    # That should give more than enough time for the
    # new docker image to be built
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
