# A defined type for user account management.
#
# WARNING: this is designed to NOT play well with local modifications. It will
# overwrite at least group membership & SSH keys. It's also intentionally
# simple, not supporting configurations that are of no use for the setup
#
# Manages:
#       User
#       Home directory
#       SSH Keys
#
# === Parameters
#
# [*ensure*]
#   Add or remove the user account [ "present" | "absent"]
#
# [*user*]
#   The user of the user to be created.
#
# [*realname*]
#   The realname for the user.
#
# [*uid*]
#   The UID to set for the new account. Must be globally unique.
#
# [*groups*]
#   An array of additional groups to add the user to.
#
#   WARNING: setting a group here means anywhere this user exists the
#            group _has_ to exist also.  More than likely they should be added
#            to the appropriate group in Admin::Groups
#
# [*gid*]
#   Sets the primary group of this user.
#
#   WARNING: Per-User Groups should not require and explicit setting
#
#   NOTE: User created files default to this group
#
# [*ssh_keys*]
#   An array of strings containing the SSH public keys.
#
# [*sudo_privs*]
#   An array of priviledges to setup via admin::sudo
#   Rarely should a user differ from an established group.
#
# [*shell*]
#   The login shell.
#
define admin::user(
                       $ensure='present',
                       $realname=undef,
                       $uid=undef,
                       $gid=undef,
                       $groups=[],
                       $ssh_keys=[],
                       $sudo_privs=[],
                       $shell='/bin/bash',
                   )
    {

    validate_re($ensure, '^(present|absent)$')

    $ensure_dir = $ensure ? {
        'absent'   => 'absent',
        'present'  => 'directory',
    }

    #can't just reassign $uid to $gid if undef
    if ($gid) {
        $group_id = $gid
    }
    else {
        $group_id = $uid
    }

    user { $name:
        ensure     => $ensure,
        name       => $name,
        uid        => $uid,
        comment    => $realname,
        gid        => $group_id,
        groups     => $groups,
        membership => 'inclusive',
        shell      => $shell,
        managehome => false, # we do it manually below
        allowdupe  => false,
    }

    if ($ensure == 'present') {
        #Going the extra mile to ensure GID consistency
        #for per-user groups across the environment
        admin::group { $name:
            ensure  => $ensure,
            members => [$name],
            gid     => $group_id,
        }
    } else {

        #Puppet Bug: https://tickets.puppetlabs.com/browse/PUP-1153
        #Puppet does not correctly unwind dependencies for User->Group Removal
        #correctly.  Handling it manually for now.  Revist for Puppet 3
        User[$name]
        ->
        exec { 'manual_group_removal':
            command   => "/usr/sbin/groupdel ${name}",
            onlyif    => "/bin/grep -E ^${name}: /etc/group",
            logoutput => true,
        }
    }

    file { "/home/${name}":
        ensure       => $ensure_dir,
        source       => [
            "puppet:///modules/admin/home/${name}/",
            'puppet:///modules/admin/home/skel/',
        ],
        sourceselect => 'first',
        recurse      => 'remote',
        mode         => '0644',
        owner        => $name,
        group        => $group_id,
        force        => true,
        tag          => 'user-home',
    }

    # use regular file resources instead of the special ssh_authorized_keys
    # resources since we *exclusively* manage ssh keys and do not coexist
    # with local ones

    $ssh_authorized_keys = join($ssh_keys, "\n")

    # XXX: move under /etc/ssh/userkeys
    file { "/home/${name}/.ssh":
        ensure  => $ensure_dir,
        owner   => $name,
        group   => $group_id,
        mode    => '0700',
        force   => true,
        tag     => 'user-ssh',
    }

    file { "/home/${name}/.ssh/authorized_keys":
        ensure  => $ensure,
        owner   => $name,
        group   => $group_id,
        mode    => '0600',
        content => $ssh_authorized_keys,
        force        => true,
        tag     => 'user-ssh',
    }

    if !empty($sudo_privs) {
        admin::sudo { $name:
            ensure     => $ensure,
            filename   => $name,
            privs      => $sudo_privs,
        }
    }
}
