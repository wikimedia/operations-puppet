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
#  An array of sudo privileges to setup
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
        sudo::group { $name:
            ensure     => $ensure,
            privileges => $privileges,
        }
    }
}
