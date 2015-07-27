# A defined type for group creation / user realization from hash
#
# === Parameters
#
# [*name*]
#  Hash group name
#
# [*phash*]
#  Hash that contains valid group data
#
# [*only_ops_sudo*]
#  When set to true, only the 'ops' group can have any privileges.

define admin::hashgroup(
    $phash={},
    $only_ops_sudo=false
)
{

    #explicit error as otherwise it goes forward later
    #complaining of 'invalid hash' which is hard to track down
    if !has_key($phash['groups'], $name) {
        fail("${name} is not a valid group name")
    }

    $gdata = $phash['groups'][$name]
    if has_key($gdata, 'posix_name') {
        $group_name = $gdata['posix_name']
    } else {
        $group_name = $name
    }

    $privileges = $gdata['privileges']
    if $only_ops_sudo && $name != 'ops' {
        $privileges = []
    }
    admin::group { $group_name:
        ensure     => $gdata['ensure'],
        gid        => $gdata['gid'],
        privileges => $privileges,
    }
}
