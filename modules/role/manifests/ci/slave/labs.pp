# filtertags: labs-project-git labs-project-integration
class role::ci::slave::labs {
    requires_realm('labs')

    system::role { 'ci::slave::labs':
        description => 'CI Jenkins slave on labs' }

    include ::profile::ci::worker_localhost
    include ::profile::zuul::cloner

    # Debian slaves are used to build Debian packages for all our distributions
    system::role { '::package_builder':
        description => 'CI package building',
    }
    include ::profile::phabricator::arcanist

    include ::profile::ci::package_builder

    # And a second mounted on /srv
    contint::tmpfs { 'tmpfs for jenkins CI labs slave on /srv':
        # Jobs expect the tmpfs to be in $HOME/tmpfs
        mount_point => '/srv/home/jenkins-deploy/tmpfs',
        size        => '256M',
        require     => File['/srv/home/jenkins-deploy'],
    }

    include contint::composer
    include contint::slave_scripts

    # Include package unsafe for production
    include contint::packages::labs

    include profile::ci::hhvm

    include contint::php

    include role::ci::slave::labs::common

    include profile::ci::browsers

    # The sshkey resource seems to modify file permissions and make it
    # unreadable - this is a known bug (https://tickets.puppetlabs.com/browse/PUP-2900)
    # Trying to define this file resource, and notify the resource to be ensured
    # from the sshkey resource, to see if it fixes the problem
    if !$::use_puppetdb {
        file { '/etc/ssh/ssh_known_hosts':
            ensure    => file,
            mode      => '0644',
            subscribe => Sshkey['gerrit'],
        }
    }

    # Add gerrit as a known host
    sshkey { 'gerrit':
        ensure => 'present',
        name   => 'gerrit.wikimedia.org',
        key    => 'AAAAB3NzaC1yc2EAAAADAQABAAAAgQCF8pwFLehzCXhbF1jfHWtd9d1LFq2NirplEBQYs7AOrGwQ/6ZZI0gvZFYiEiaw1o+F1CMfoHdny1VfWOJF3mJ1y9QMKAacc8/Z3tG39jBKRQCuxmYLO1SWymv7/Uvx9WQlkNRoTdTTa9OJFy6UqvLQEXKYaokfMIUHZ+oVFf1CgQ==',
        type   => 'ssh-rsa',
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
