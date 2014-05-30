# A defined type for group creation / user realization from hash
#
# === Parameters
#
# [*name*]
#  Hash group name
#
# [*phash*]
#  Hash that contains valid group data

define admin::hashgroup(
    $phash={},
)
{

    #explicit error as otherwise it goes forward later
    #complaining of 'invalid hash' which is hard to track down
    if !has_key($phash['groups'], $name) {
        fail("${name} is not a valid group name")
    }

    $gdata = $phash['groups'][$name]
    if !has_key($gdata, 'posix_name') {
        $group_name = $gdata['posix_name']
    } else {
        $group_name = $name
    }

    admin::group { $group_name:
        ensure => $gdata['ensure'],
        gid    => $gdata['gid'],
        privs  => $gdata['privs'],
    }
}
