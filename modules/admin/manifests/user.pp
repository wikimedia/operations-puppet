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
# [*privs*]
#  An array of priviledges to setup via admin::sudo
#  Rarely should a user differ from an established group.
#
# [*ssh_keys*]
#  An array of strings containing the SSH public keys.
#

define admin::user (
    $ensure   = 'present',
    $uid      = undef,
    $gid      = undef,
    $groups   = [],
    $comment  = '',
    $shell    = '/bin/bash',
    $privs    = undef,
    $ssh_keys = [],
    )
{
    validate_re($ensure, '^(present|absent)$')

    $ensure_dir = $ensure ? {
        'absent'   => 'absent',
        'present'  => 'directory',
    }

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
            ensure       => $ensure_dir,
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
        if !empty($ssh_keys) {

            if !is_array($ssh_keys) {
                fail("${name} does not have a correct ssh_keys array: ${ssh_keys}")
            }

            $ssh_authorized_keys = join($ssh_keys, "\n")

            file { "/home/${name}/.ssh":
                ensure  => $ensure_dir,
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
    }

    if !empty($privs) {
        admin::sudo { $name:
            ensure => $ensure,
            privs  => $privs,
        }
    }
}
