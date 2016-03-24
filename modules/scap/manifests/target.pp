# == Define scap::target
#
# Sets up a scap3 target for a deployment repository.
# This will include ths scap package and ferm fules,
# ensure that the $deploy_user has proper sudo rules
# and public key installed.
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
# [*package_name*]
#   the name of the scap3 deployment package Default: $title
#
# [*manage_user*]
#   Specify whether to create a User resource for the $deploy_user.
#   This should be set to false if you have defined the user elsewhere.
#   Default: true
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
    $package_name = $title,
    $manage_user = true,
    $sudo_rules = [],
) {
    # Include scap3 package and ssh ferm rules.
    include scap
    include scap::ferm

    if $manage_user {
        user { $deploy_user:
            ensure     => present,
            shell      => '/bin/bash',
            home       => '/var/lib/scap',
            system     => true,
            managehome => true,
        }
        group { $deploy_user:
            ensure => present,
            name   => $deploy_user,
            system => true,
        }
    } else {
        User[$deploy_user] -> Scap::Target[$title]
    }

    package { $package_name:
        install_options => [{
                  owner => $deploy_user}],
        provider        => 'scap3',
        require         => [Package['scap'], User[$deploy_user]],
    }

    if !defined(Ssh::Userkey[$deploy_user]) {
        ssh::userkey { $deploy_user:
            source => $public_key_source,
        }
    }

    # XXX: Temporary work-around for switching services from Trebuchet to Scap3
    # The Scap3 provider doesn't touch the target dir if it's already a git repo
    # which means that even after switching the provider we end up with the
    # wrong user (root) owning it. Therefore, as a temporary measure we chown
    # the target dir's parent so that the subsequent invocation of deploy-local
    # is able to create the needed dirs and symlinks
    $chown_user = "${deploy_user}:${deploy_user}"
    $name_array = split($package_name, '/')
    $pkg_root = inline_template(
        '<%= @name_array[0,@name_array.size - 1].join("/") %>'
    )
    $chown_target = "/srv/deployment/${pkg_root}"
    exec { "chown ${package_name} for ${deploy_user}":
        command => "/bin/chown -R ${chown_user} ${chown_target}",
        # perform the chown only if root is the effective owner
        onlyif  => "/usr/bin/test -O /srv/deployment/${package_name}",
        require => [User[$deploy_user], Group[$deploy_user]]
    }

    # Allow deploy user user to sudo -u $user, and to sudo /usr/sbin/service
    # if $service_name is defined.
    #
    # NOTE: sudo -u $user is currently needed by scap3.
    # TODO: Remove this when it is no longer needed.
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
            privileges => concat($privileges, $sudo_rules),
        }
    }

}
