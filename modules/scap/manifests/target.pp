# == Define scap::target
#
# Sets up a scap3 target for a deployment repository.
# This will include ths scap package and ferm fules,
# ensure that the $deploy_user has proper sudo rules
# and public key installed, and that the $deploy_path
# is set up with proper permissions.
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
# [*deploy_path*]
#   Path at which scap3 will deploy.
#   Default: /srv/deployment/$title
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
#       deploy_path => '/srv/i/am/special/eventlogging/eventlogging'
#   }
#
define scap::target(
    $deploy_user,
    $public_key_source,
    $deploy_path = "/srv/deployment/${title}",
) {
    User[$user] -> Scap::Target[$title]

    # Include scap3 package and ssh ferm rules.
    include scap
    include scap::ferm

    # Allow deploy user user to sudo -u $user
    # This is needed by scap3.
    # TODO: Remove this if no longer needed.
    if !defined(Sudo::User["scap_${deploy_user}"]) {
        sudo::user { "scap_${deploy_user}":
            user       => $deploy_user,
            privileges => ["ALL=(${deploy_user}) NOPASSWD: ALL"],
        }
    }

    if !defined(Ssh::Userkey[$deploy_user]) {
        ssh::userkey { $deploy_user:
            source => $public_key_source,
        }
    }

    # $parent_dir needs to be writable by deploy user in order
    # for scap to be able to create the -cache directories it needs.
    # This in case you are deploying a repository with
    # a '/' in the name, e.g. eventlogging/eventlogging.  This makes
    # sure that /srv/deployment/eventlogging is writable by
    # scap.
    #
    # TODO: if scap3 -cache directory location becomes configurable,
    # change this.
    # (dirname() stdlib puppet function not available???)
    $parent_dir = inline_template('<%= File.dirname(@deploy_path) %>')
    if !defined(File[$parent_dir]) {
        file { $parent_dir:
            ensure  => 'directory',
            owner   => $deploy_user,
            mode    => '0775',
        }
    }

    file { $deploy_path:
        ensure  => 'directory',
        owner   => $deploy_user,
        mode    => '0775',
        # Set permissions recursively.
        recurse => true,
    }
}
