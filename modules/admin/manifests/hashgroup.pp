# A defined type for group creation / user realization from hash
#
# === Parameters
#
# [*name*]
#  Hash group name
#
define admin::hashgroup(
)
{

    #explicit error as otherwise it goes forward later
    #complaining of 'invalid hash' which is hard to track down
    if !has_key($::admin::data['groups'], $name) {
        fail("${name} is not a valid group name")
    }

    $gdata = $::admin::data['groups'][$name]
    if has_key($gdata, 'posix_name') {
        $group_name = $gdata['posix_name']
    } else {
        $group_name = $name
    }

    admin::group { $group_name:
        ensure     => $gdata['ensure'],
        gid        => $gdata['gid'],
        privileges => $gdata['privileges'],
    }
}
