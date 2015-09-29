# == Class restbase::deploy
#
# Creates user and permissions for deploy user
# on restbase hosts
#
# === Parameters
#
# [*public_key*]
#   This is the public_key for the deploy-service user. The private part of this
#   key should reside in the private puppet repo for the environment. By default
#   this public key is set to the deploy-service user's public key for production
#   private puppet—it should be overwritten using hiera in non-production
#   environements.

class restbase::deploy(
    $public_key_file = 'puppet:///modules/restbase/servicedeploy_rsa.pub',
) {
    $user = 'deploy-service'

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

    # Using trebuchet provider while scap service deployment is under
    # development—chicken and egg things
    #
    # This should be removed once scap3 is in a final state
    package { 'scap/scap':
        provider => 'trebuchet',
    }

    # Rather than futz with adding new functionality to allow a deployment
    # user set per repository in trebuchet, I'm running an exec here
    $dir = '/srv/deployment/restbase/deploy'
    exec { 'chown deploy-service':
        command => "/bin/chown -R ${user} ${dir}",
        unless  => "/usr/bin/test $(/usr/bin/stat -c'%U' ${dir}) = ${user}"
    }

    sudo::user { $user:
        privileges => [
            "ALL = (${user}) NOPASSWD: ALL",
            'ALL = (root) NOPASSWD: /usr/sbin/service restbase restart',
        ]
    }

}
