# A defined type for group mangement
#
# Manages:
#       System Group
#       Group Members
#       GID
#
# === Parameters
#
# [*ensure*]
#   Add or remove the user group [ "present" | "absent"]
#
# [*members*]
#   An array of additional groups to add the user to.
#
# [*gid*]
#   Sets the group id
#
# [*sudo_privs*]
#   An array of priviledges to setup via admin::sudo
#
define admin::group(
                    $ensure='present',
                    $members=[],
                    $allowdupe=false,
                    $gid=undef,
                    $sudo_privs=[],
                   )
    {

    validate_re($ensure, '^(present|absent)$')

    group { $name:
        ensure    => $ensure,
        name      => $name,
        allowdupe => $allowdupe,
        gid       => $gid,
    }

    if !empty($sudo_privs) { 
        admin::sudo { $name:
            ensure     => $ensure,
            filename   => $name,
            privs      => $sudo_privs,
            is_group   => true,
        }
    }
}
