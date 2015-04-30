# A defined type for user account management.
#
# WARNING: this is designed to NOT play well with local modifications.
#
# === Parameters
#
# [*name*]
#  The user of the user to be created.
#
# [*ensure*]
#  Add or remove the user account [ "present" | "absent"]
#
# [*uid*]
#  The UID to set for the new account. Must be globally unique.
#
# [*gid*]
#  Sets the primary group of this user.
#
#  NOTE: User created files default to this group
#
# [*groups*]
#  An array of additional groups to add the user to.
#
#  NOTE: user membership should almost exclusively be handled in the
#  external definition format (yaml)
#
#  WARNING: setting a group here means anywhere this user exists the
#           group _has_ to exist also.  More than likely they should be added
#           to the appropriate group in Admin::Groups
#
# [*comment*]
#  Typicaly the realname for the user.
#
# [*shell*]
#  The login shell.
#
# [*privileges*]
#  An array of sudo privileges to setup
#  Rarely should a user differ from an established group.
#
# [*ssh_keys*]
#  An array of strings containing the SSH public keys.
#

define admin::user (
    $ensure     = 'present',
    $uid        = undef,
    $gid        = undef,
    $groups     = [],
    $comment    = '',
    $shell      = '/bin/bash',
    $privileges = undef,
    $ssh_keys   = [],
    )
{
    validate_ensure($ensure)

    user { $name:
        ensure     => $ensure,
        name       => $name,
        uid        => $uid,
        comment    => $comment,
        gid        => $gid,
        groups     => [],
        shell      => $shell,
        managehome => false, # we do it manually below
        allowdupe  => false,
    }

    #This is all absented by the above /home/${user} cleanup
    #Puppet chokes if we try to absent subfiles to /home/${user}
    if $ensure == 'present' {

        file { "/home/${name}":
            ensure       => ensure_directory($ensure),
            source       => [
                "puppet:///modules/admin/home/${name}/",
                'puppet:///modules/admin/home/skel/',
            ],
            sourceselect => 'first',
            recurse      => 'remote',
            mode         => '0644',
            owner        => $name,
            group        => $gid,
            force        => true,
            tag          => 'user-home',
            require      => User[$name],
        }

        # XXX: move under /etc/ssh/userkeys
        # we want to exclusively manage ssh keys in puppet
        if !is_array($ssh_keys) {
            fail("${name} is not a valid ssh_keys array: ${ssh_keys}")
        }

        if !empty($ssh_keys) {
            $ssh_authorized_keys = join($ssh_keys, "\n")
        } else {
            $ssh_authorized_keys = ''
        }

        file { "/home/${name}/.ssh":
            ensure  => ensure_directory($ensure),
            owner   => $name,
            group   => $gid,
            mode    => '0700',
            force   => true,
            tag     => 'user-ssh',
            require => File["/home/${name}"],
        }

        file { "/home/${name}/.ssh/authorized_keys":
            ensure  => $ensure,
            owner   => $name,
            group   => $gid,
            mode    => '0400',
            content => $ssh_authorized_keys,
            force   => true,
            tag     => 'user-ssh',
            require => File["/home/${name}/.ssh"],
        }
    }

    # If specified privilege is empty we manage
    # separately from the user as a whole and cleanup
    if empty($privileges) {
        $privileges_ensure = 'absent'
    } else {
        $privileges_ensure = $ensure
    }

    sudo::user { $name:
        ensure     => $privileges_ensure,
        privileges => $privileges,
    }
}
