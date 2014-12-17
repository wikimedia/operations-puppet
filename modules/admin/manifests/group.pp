# A defined type for system group mangement
#
# === Parameters
#
# [*name*]
#  Group name
#
# [*ensure*]
#  Add or remove the user group [ "present" | "absent" ]
#
# [*gid*]
#  Sets the group id
#
# [*privileges*]
#  An array of privileges to setup via admin::sudo
#

define admin::group(
    $ensure         = 'present',
    $gid            = undef,
    $privileges     = [],
)
    {

    # sans specified $gid we assume system group and do not create
    if ($ensure == 'absent') or ($gid) {
        group { $name:
            ensure    => $ensure,
            name      => $name,
            allowdupe => false,
            gid       => $gid,
        }
    }

    if !empty($privileges) {
        admin::sudo { $name:
            ensure     => $ensure,
            privileges => $privileges,
            is_group   => true,
        }
    }
}
