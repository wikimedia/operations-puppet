# == Define: admin::user
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

define admin::account(
  $ensure='present',
) {
    validate_re($ensure, '^(present|absent)$')

    include admin::data
    $users = $admin::data::users
    $userinfo = $users[$name]

    notify { $userinfo: }

    $ensure_dir = $ensure ? {
        'absent'   => 'absent',
        'present'  => 'directory',
    }

   #     'akosiaris' => {
   #         realname => 'Alexandros Kosiaris',
   #         uid      => 642,
   #         gid      => 'wikidev',
   #     },

    user { $name:
        ensure     => $ensure,
        name       => $userinfo[realname],
        uid        => $userinfo[uid],
        comment    => $userinfo[$realname],
        gid        => $userinfo[gid],
        #groups     => $groups,
        membership => 'inclusive',
        #shell      => $shell,
        #managehome => false, # we do it manually below
        #allowdupe  => false,
    }
}
