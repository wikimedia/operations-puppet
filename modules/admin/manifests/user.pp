# @summary A defined type for user account management.
#
# WARNING: this is designed to NOT play well with local modifications.
#
# @param name The user of the user to be created.
# @param ensure Add or remove the user account [ "present" | "absent"]
# @param uid The UID to set for the new account. Must be globally unique.
# @param gid Sets the primary group of this user.
#  NOTE: User created files default to this group
# @param groups
#  An array of additional groups to add the user to.
#
#  NOTE: user membership should almost exclusively be handled in the
#  external definition format (yaml)
#
#  WARNING: setting a group here means anywhere this user exists the
#           group _has_ to exist also.  More than likely they should be added
#           to the appropriate group in Admin::Groups
# @param comment Typically the realname for the user.
# @param shell The login shell.
# @param privileges
#  An array of sudo privileges to setup
#  Rarely should a user differ from an established group.
# @param ssh_keys An array of strings containing the SSH public keys.
#
define admin::user (
    Wmflib::Ensure          $ensure     = present,
    Optional[Integer]       $uid        = undef,
    Optional[Integer]       $gid        = undef,
    Array[String]           $groups     = [],
    String                  $comment    = '',
    String                  $shell      = '/bin/bash',
    Optional[Array[String]] $privileges = undef,
    Array[String]           $ssh_keys   = [],
    Stdlib::Unixpath        $home_dir   = "/home/${name}",
) {

    include admin

    user { $name:
        ensure     => $ensure,
        name       => $name,
        uid        => $uid,
        comment    => $comment,
        gid        => $gid,
        groups     => [],
        shell      => $shell,
        allowdupe  => false,
        # managehome is controlled at the class level se we can ensure all users for
        # a specific role, profile, host are all configured the same
        # regardless of this parameter we still sync files below from
        # modules/admin/files/home/${user}
        managehome => $admin::managehome,
    }

    # This is all absented by the above /home/${user} cleanup
    # Puppet chokes if we try to absent subfiles to /home/${user}
    if $ensure == 'present' {
        file { $home_dir:
            ensure       => stdlib::ensure($ensure, 'directory'),
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
            require      => User[$name],
        }
    }

    # /etc/ssh/userkey is recursively-managed,
    # automatically purged, so user keys not defined
    # (as resource) will be automatically dropped.
    if !empty($ssh_keys) {
        ssh::userkey { $name:
            ensure  => $ensure,
            content => join($ssh_keys, "\n"),
        }
    }

    if !empty($privileges) {
        sudo::user { $name:
            ensure     => $ensure,
            privileges => $privileges,
        }
    }
}
