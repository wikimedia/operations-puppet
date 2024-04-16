# OpenStack zuul
#
# A Jenkins/Gerrit gateway written in python. This is a drop in replacement
# for Jenkins "Gerrit Trigger" plugin.
#
# == Class: zuul
#
# Install Zuul
#
class zuul ( ){

    include zuul::user

    ensure_packages(['python2.7', 'virtualenv', 'make'])

    # Both merger and server require the zuul class
    if !defined(Scap::Target['zuul/deploy']) {
        scap::target { 'zuul/deploy':
            deploy_user => 'deploy-zuul',
        }
    }

    file { '/var/log/zuul':
        ensure => directory,
        owner  => 'zuul',
        group  => 'adm',
        mode   => '0755',
    }

    file { '/usr/local/bin/zuul':
        ensure => link,
        target => '/srv/deployment/zuul/venv/bin/zuul',
    }
}

