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

    # explicit error as otherwise it goes forward later
    # complaining of 'invalid hash' which is hard to track down
    if !$admin::data['groups'].has_key($name) {
        fail("${name} is not a valid group name")
    }

    $gdata = $admin::data['groups'][$name]
    $group_name = $gdata.has_key('posix_name') ? {
        true    => $gdata['posix_name'],
        default => $name,
    }
    if $gdata.has_key('deprecated') and $gdata['deprecated'] and !$gdata['members'].empty {
        fail("${name}: group is deprecated and should have no members")
    }
    if $gdata['system'] {
        unless $gdata['gid'] =~ Integer[900,950] {
            fail("${name}: system group defined with incorrect gid (${gdata['gid']})")
        }
        admin::group { $group_name:
            ensure => $gdata['ensure'],
            gid    => $gdata['gid'],
        }
    } else {
        if $gdata['gid'] =~ Integer[900,950] {
            fail("${name}: user group defined with incorrect gid (${gdata['gid']})")
        }
        admin::group { $group_name:
            ensure     => $gdata['ensure'],
            gid        => $gdata['gid'],
            privileges => $gdata['privileges'],
        }
    }
}
