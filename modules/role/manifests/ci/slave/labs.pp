# filtertags: labs-project-git labs-project-integration labs-project-ci-staging
class role::ci::slave::labs {
    requires_realm('labs')

    system::role { 'role::ci::slave::labs':
        description => 'CI Jenkins slave on labs' }

    # Debian slaves are used to build Debian packages for all our distributions
    if os_version('debian >= jessie') {
        system::role { '::package_builder':
            description => 'CI package building',
        }
        include ::contint::package_builder
    }

    class { 'contint::worker_localhost':
        owner => 'jenkins-deploy',
    }

    contint::tmpfs { 'tmpfs for jenkins CI labs slave':
        # Jobs expect the tmpfs to be in $HOME/tmpfs
        mount_point => '/mnt/home/jenkins-deploy/tmpfs',
        size        => '256M',
        require     => File['/mnt/home/jenkins-deploy'],
    }

    # Trebuchet replacement on labs
    include contint::composer
    include contint::phpunit
    include contint::slave_scripts

    # Include package unsafe for production
    include contint::packages::labs

    if os_version('ubuntu >= trusty') {
        include contint::hhvm
    }

    include contint::php

    include role::ci::slave::labs::common

    class { '::zuul': }

    if os_version('ubuntu >= trusty || debian >= jessie') {
        include contint::browsers

        class { 'role::ci::slave::browsertests':
            require => [
                Class['role::ci::slave::labs::common'], # /mnt
                Class['contint::packages::labs'], # realize common packages first
            ]
        }
    }

    # The sshkey resource seems to modify file permissions and make it
    # unreadable - this is a known bug (https://tickets.puppetlabs.com/browse/PUP-2900)
    # Trying to define this file resource, and notify the resource to be ensured
    # from the sshkey resource, to see if it fixes the problem
    file { '/etc/ssh/ssh_known_hosts':
        ensure => file,
        mode   => '0644',
    }

    # Add gerrit as a known host
    sshkey { 'gerrit':
        ensure       => 'present',
        name         => 'gerrit.wikimedia.org',
        host_aliases => ['208.80.154.81'],
        key          => 'AAAAB3NzaC1yc2EAAAADAQABAAAAgQCF8pwFLehzCXhbF1jfHWtd9d1LFq2NirplEBQYs7AOrGwQ/6ZZI0gvZFYiEiaw1o+F1CMfoHdny1VfWOJF3mJ1y9QMKAacc8/Z3tG39jBKRQCuxmYLO1SWymv7/Uvx9WQlkNRoTdTTa9OJFy6UqvLQEXKYaokfMIUHZ+oVFf1CgQ==',
        type         => 'ssh-rsa',
        notify       => File['/etc/ssh/ssh_known_hosts'],
    }

    # Put the mysql-server db on tmpfs

    exec { 'create-var-lib-mysql-mountpoint':
        creates => '/var/lib/mysql',
        command => '/bin/mkdir -p /var/lib/mysql',
    }

    mount { '/var/lib/mysql':
        ensure  => mounted,
        atboot  => true,
        device  => 'none',
        fstype  => 'tmpfs',
        options => 'defaults,size=256M',
        require => Exec['create-var-lib-mysql-mountpoint'],
    }

    file { '/var/lib/mysql':
        ensure  => directory,
        owner   => 'mysql',
        group   => 'mysql',
        mode    => '0775',
        require => Mount['/var/lib/mysql'],
    }

    exec { 'create-mysql-datadir':
        path    => '/bin:/usr/bin',
        creates => '/var/lib/mysql/.created',
        command => 'mysql_install_db --user=mysql --datadir=/var/lib/mysql && touch /var/lib/mysql/.created',
        require => [ File['/var/lib/mysql'], Package['mysql-server'] ],
    }

    file { '/etc/init/mysql.override':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => "manual\n",
        require => Package['mysql-server'],
    }

    service { 'mysql':
        ensure   => running,
        enable   => true,
        # With the service being debian, which are the generic init independent
        # service wrappers create by debian and thus also work on ubuntu with
        # upstart, it won't instruct upstart to enable the service, thus not
        # reverting setting it to manual.
        provider => 'debian',
        require  => Exec['create-mysql-datadir'],
    }

}
