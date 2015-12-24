# Set up a Jenkins slave suitable for Continuous Integration jobs execution.
class role::ci::slave {

    system::role { 'role::ci::slave': description => 'CI slave runner' }

    include contint::packages
    include role::zuul::install

    package {
        [
            'integration/mediawiki-tools-codesniffer',
            'integration/phpunit',
            'integration/phpcs',
            'integration/php-coveralls',
            'integration/slave-scripts',
        ]:
        provider => 'trebuchet',
    }

    class { 'jenkins::slave':
        ssh_key => 'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA4QGc1Zs/S4s7znEYw7RifTuZ4y4iYvXl5jp5tJA9kGUGzzfL0dc4ZEEhpu+4C/TixZJXqv0N6yke67cM8hfdXnLOVJc4n/Z02uYHQpRDeLAJUAlGlbGZNvzsOLw39dGF0u3YmwDm6rj85RSvGqz8ExbvrneCVJSaYlIRvOEKw0e0FYs8Yc7aqFRV60M6fGzWVaC3lQjSnEFMNGdSiLp3Vl/GB4GgvRJpbNENRrTS3Te9BPtPAGhJVPliTflVYvULCjYVtPEbvabkW+vZznlcVHAZJVTTgmqpDZEHqp4bzyO8rBNhMc7BjUVyNVNC5FCk+D2LagmIriYxjirXDNrWlw== jenkins@gallium from="208.80.154.135"',
        user    => 'jenkins-slave',
        workdir => '/srv/ssd/jenkins-slave',
        # Mount is handled on the node definition
        require => Mount['/srv/ssd'],
    }

    # .gitconfig file required for rare git write operations
    git::userconfig { '.gitconfig for jenkins-slave user':
        homedir  => '/var/lib/jenkins-slave',
        settings => {
            'user' => {
                'name'  => 'Wikimedia Jenkins Bot',
                'email' => "jenkins-slave@${::fqdn}",
            },  # end of [user] section
        },  # end of settings
        require  => User['jenkins-slave'],
    }

    # Maven requires a webproxy on production slaves
    class { 'contint::maven_webproxy':
        homedir => '/var/lib/jenkins-slave',
        owner   => 'jenkins-slave',
        group   => 'jenkins-slave',
    }

    contint::tmpfs { 'tmpfs for jenkins CI slave':
        mount_point => '/var/lib/jenkins-slave/tmpfs',
        size        => '512M',
    }
    nrpe::monitor_service { 'ci_tmpfs':
        description  => 'CI tmpfs disk space',
        nrpe_command => '/usr/lib/nagios/plugins/check_disk -w 20% -c 5% -e -p /var/lib/jenkins-slave/tmpfs',
    }

    # user and private key for Travis integration
    # RT: 8866
    user { 'npmtravis':
        home       => '/home/npmtravis',
        managehome => true,
        system     => true,
    }

    file { '/home/npmtravis/.ssh':
        ensure  => directory,
        owner   => 'npmtravis',
        mode    => '0500',
        require => User['npmtravis'],
    }

    file { '/home/npmtravis/.ssh/npmtravis_id_rsa':
        ensure  => present,
        owner   => 'npmtravis',
        mode    => '0400',
        content => secret('ssh/ci/npmtravis_id_rsa'),
        require => File['/home/npmtravis/.ssh'],
    }

    file { '/srv/localhost-worker':
        ensure => directory,
        mode   => '0775',
        owner  => 'jenkins-slave',
        group  => 'jenkins-slave',
    }
    include contint::worker_localhost

    # Ganglia diskstat plugin is being evaluated on contint production slaves
    # servers merely to evaluate it for the standard role. -- hashar, 23-Oct-2013
    ganglia::plugin::python { 'diskstat': }
}

