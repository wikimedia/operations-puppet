# == Define scap::target
#
# Sets up a scap3 target for a deployment repository.
# This will include ths scap package and ferm fules,
# ensure that the $deploy_user has proper sudo rules
# and public key installed.
#
# NOTE: This define will not manage $deploy_user for you.  You must
# ensure that this is done somewhere else in puppet first, e.g.
#   user { 'my_deploy_user': ... }
#
# == Params
# [*deploy_user*]
#   user that will be used for deployments
#
# [*public_key_source*]
#   puppet source argument to pass to ssh::userkey for installing
#   $deploy_user's public ssh key.
#
# [*service_name*]
#   service name that should be allowed to be restarted via sudo by
#   deploy_user.  Default: undef.
#
# Usage:
#
#   scap::target { 'mockbase':
#       deploy_user => 'deploy-mockbase',
#       public_key_source => 'puppet://modules/mockbase/deploy-test_rsa.pub'
#   }
#
#   scap::target { 'eventlogging/eventlogging':
#       deploy_user => 'eventlogging',
#       public_key_source => "puppet:///modules/eventlogging/deployment/eventlogging_rsa.pub.${::realm}",
#   }
#
define scap::target(
    $deploy_user,
    $public_key_source,
    $service_name = undef,
) {
    User[$deploy_user] -> Scap::Target[$title]

    # Include scap3 package and ssh ferm rules.
    include scap
    include scap::ferm

    package { $title:
        owner    => $deploy_user,
        provider => 'scap',
        require  => Package['scap'],
    }

    # Allow deploy user user to sudo -u $user, and to sudo /usr/sbin/service
    # if $service_name is defined.
    # sudo -u $user is currently needed by scap3.  TODO: Remove this
    # when it is no longer needed.
    $privileges = $service_name ? {
        undef   => [
            "ALL=(${deploy_user}) NOPASSWD: ALL",
        ],
        default => [
            "ALL=(${deploy_user}) NOPASSWD: ALL",
            "ALL=(root) NOPASSWD: /usr/sbin/service ${service_name} *",
        ],
    }
    if !defined(Sudo::User["scap_${deploy_user}"]) {
        sudo::user { "scap_${deploy_user}":
            user       => $deploy_user,
            privileges => $privileges,
        }
    }

    if !defined(Ssh::Userkey[$deploy_user]) {
        ssh::userkey { $deploy_user:
            source => $public_key_source,
        }
    }

}
