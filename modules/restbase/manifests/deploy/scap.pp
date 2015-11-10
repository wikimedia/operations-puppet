# == Class restbase::deploy::scap
#
# Ensures that restbase target is setup correctly for deployment via Scap3
#
# === Parameters
#
# [*public_key*]
#   This is the public_key for the deploy-service user. The private part of this
#   key should reside in the private puppet repo for the environment. By default
#   this public key is set to the deploy-service user's public key for
#   production private puppet -- it should be overwritten using hiera in
#   non-production environments.
# [*user*]
#   User that should run the scap deployment and own config files
# [*dir*]
#   Directory into which restbase will be deployed

class restbase::deploy::scap (
    $public_key_file = 'puppet:///modules/restbase/servicedeploy_rsa.pub',
    $user            = 'deploy-service',
    $dir             = '/srv/deployment/restbase'
) {
    include ::scap
    include ::role::scap::target

    class { 'restbase::config':
        owner => $user,
    }

    user { $user:
        ensure     => present,
        shell      => '/bin/bash',
        home       => '/var/lib/scap',
        system     => true,
        managehome => true,
    }

    ssh::userkey { $user:
        source => $public_key_file,
    }


    file { $dir:
        ensure => directory,
        mode   => '0775',
        owner  => $user,
        group  => 'wikidev',
    }

    file { "${dir}/deploy":
        ensure => directory,
        mode   => '0775',
        owner  => $user,
        group  => 'wikidev',
    }

    file { "${dir}/deploy-cache":
        ensure => directory,
        mode   => '0775',
        owner  => $user,
        group  => 'wikidev',
    }

    # Rather than futz with adding new functionality to allow a deployment
    # user set per repository in trebuchet, I'm running an exec here
    exec { "chown resetbase ${user}":
        command => "/bin/chown -R ${user} ${dir}",
        unless  => "/usr/bin/test $(/usr/bin/stat -c'%U' ${dir}) = ${user}",
        require => [File["${dir}/deploy"], File["${dir}/deploy-cache"]],
    }

    sudo::user { $user:
        privileges => [
            "ALL = (${user}) NOPASSWD: ALL",
            'ALL = (root) NOPASSWD: /usr/sbin/service restbase *',
        ]
    }

}
