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

    include contint::composer
    include contint::slave_scripts

    # Include package unsafe for production
    include contint::packages::labs

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

}
