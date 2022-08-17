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
# @param home_dir the home directory to use
#
define admin::user (
    Wmflib::Ensure                         $ensure     = present,
    Optional[Integer]                      $uid        = undef,
    Optional[Integer]                      $gid        = undef,
    Array[String]                          $groups     = [],
    Optional[String]                       $comment    = undef,
    String                                 $shell      = '/bin/bash',
    Optional[Array[String]]                $privileges = undef,
    Array[String]                          $ssh_keys   = [],
    Variant[Enum['none'],Stdlib::Unixpath] $home_dir   = "/home/${name}",
) {

    include admin
    $shell_package = $shell.basename
    $shell_require = $shell_package in $admin::addtional_shells ? {
        true    => Package[$shell_package],
        default => undef,
    }

    # Add special hack for /nonexistent dir
    # By default managehome is controlled at the class level so we
    # can ensure all users for a specific role, profile, host are
    # all configured the same regardless of this parameter we still
    # sync files below from modules/admin/files/home/${user}
    $managehome = $home_dir ? {
        '/nonexistent' => false,
        'none' => false,
        default        => $admin::managehome,
    }
    $_home_dir = $home_dir ? {
        'none'  => '/nonexistent',
        default => $home_dir,
    }
    user { $name:
        ensure     => $ensure,
        name       => $name,
        uid        => $uid,
        comment    => $comment,
        gid        => $gid,
        groups     => [],
        shell      => $shell,
        home       => $_home_dir,
        allowdupe  => false,
        managehome => $managehome,
        require    => $shell_require,
    }

    # This is all absented by the above /home/${user} cleanup
    # Puppet chokes if we try to absent subfiles to /home/${user}
    if $ensure == 'present' and $_home_dir != '/nonexistent' {
        file { $_home_dir:
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
