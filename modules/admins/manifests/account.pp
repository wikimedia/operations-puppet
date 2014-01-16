# == Define: admins::account
#
# A defined type for user account management. It creates (or deletes) at least
# a User resource, plus virtual resources for the group, home directory and SSH
# authorized key of the user.
#
# WARNING: this is designed to NOT play well with local modifications. It will
# overwrite at least group membership & SSH keys. It's also intentionally #
# simple, not supporting configurations that are of no use for the setup it was
# created (passwords, system users etc.)
#
# === Parameters
#
# [*ensure*]
#   Add or remove the user account, with "present" or "absent" respectively.
#   Defaults to present.
#
# [*username*]
#   The username of the user to be created.
#   Defaults to the title of the account resource.
#
# [*realname*]
#   The gecos realname for the user.
#
# [*uid*]
#   The UID to set for the new account.
#
# [*gid*]
#   Sets the primary group of this user.
#
# [*groups*]
#   An array of additional groups to add the user to.
#   Defaults to an empty array.
#
# [*ssh_keys*]
#   An array of strings containing the SSH public keys.
#   Defaults to an empty array.
#
# [*shell*]
#   The login shell.
#   The default is '/bin/bash'
#

define admins::account(
  $ensure,
  $realname,
  $uid,
  $gid,
  $groups=[],
  $ssh_keys=[],
  $shell='/bin/bash'
  $username=$title,
) {
    validate_re($ensure, '^(present|absent)$')

    $ensure_dir = $ensure ? {
        'absent'   => 'absent',
        'present'  => 'directory',
    }

    user { $username:
        ensure     => $ensure,
        name       => $username,
        uid        => $uid,
        comment    => $realname,
        gid        => $gid,
        groups     => $groups,
        membership => 'inclusive',
        shell      => $shell,
        managehome => false, # we do it manually below
        allowdupe  => false,
    }

    case $ensure {
        'present': {
            Group[$gid] -> User[$username]
        }
        'absent': {
            User[$username] -> Group[$gid]
        }
        default: {}
    }

    @group { $gid:
        ensure    => $ensure,
        name      => $gid,
        allowdupe => false,
    }

    @file { "/home/${username}":
        ensure       => $ensure_dir,
        source       => [
            "puppet:///modules/account/home/${username}/",
            'puppet:///modules/account/home/skel/',
        ],
        sourceselect => 'first',
        recurse      => 'remote',
        mode         => '0644',
        owner        => $username,
        group        => $gid,
        require      => [ User[$username], Group[$gid] ],
        tag          => 'account/home'
    }

    # use regular file resources instead of the special ssh_authorized_keys
    # resources since we *exclusively* manage ssh keys and do not coexist
    # with local ones

    $ssh_authorized_keys = join($ssh_keys, "\n")

    # XXX: move under /etc/ssh/userkeys
    @file { "/home/${username}/.ssh":
        ensure  => $ensure_dir,
        owner   => $username,
        group   => $gid,
        mode    => '0700',
        tag     => 'account/home'
    }
    @file { "/home/${username}/.ssh/authorized_keys":
        ensure  => $ensure,
        owner   => $username,
        group   => $gid,
        mode    => '0600',
        content => $ssh_authorized_keys,
        tag     => 'account/home'
    }
}
