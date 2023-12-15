# A defined type for user creation from hash
#
# === Parameters
#
# [*name*]
#  Hash user name
#
# [*ensure_ssh_key*]
#  If the user is allowed to have a SSH key or not.
#  Useful when a user is needed on a host without
#  allowing ssh access.
#  Default: true
#
define admin::hashuser (
    Boolean $ensure_ssh_key = true,
) {
    $uinfo = $admin::data['users'][$name]

    if $uinfo['system'] {
        # ensure system users specify a home dir
        unless $uinfo.has_key('home_dir') {
            fail("${name}: system user defined without home_dir")
        }
        # Ensure system users are defined in the range 900 - 950
        unless $uinfo['uid'] =~ Integer[900,950] {
            fail("${name}: system user defined with uid (${uinfo['uid']})")
        }
        $privileges = []
        $ssh_keys = []
        $groups = []
        $comment = $name
        $shell = $uinfo.has_key('shell') ? {
            true    => $uinfo['shell'],
            default => '/usr/sbin/nologin',
        }
    } else {
        # ideally we would check that uid's are above 1000 but due to legacy that's not true
        if $gid =~ Integer[900,950] {
            fail("${name}: system user defined with incorrect gid (${gid})")
        }
        $privileges = $uinfo['privileges']
        $shell = $uinfo['shell']
        $groups = $uinfo['groups']
        $comment = $uinfo['realname']
        $ssh_keys = ($uinfo.has_key('ssh_keys') and $ensure_ssh_key) ? {
            true    => $uinfo['ssh_keys'],
            default => [],
        }
    }
    $gid = $uinfo.has_key('gid') ? {
        true    => $uinfo['gid'],
        default => $uinfo['uid']
    }
    $home_dir = $uinfo.has_key('home_dir') ? {
        true    => $uinfo['home_dir'],
        default => "/home/${name}",
    }

    admin::user { $name:
        ensure     => $uinfo['ensure'],
        uid        => $uinfo['uid'],
        gid        => $gid,
        groups     => $groups,
        comment    => $comment,
        shell      => $shell,
        privileges => $privileges,
        ssh_keys   => $ssh_keys,
        home_dir   => $home_dir,
    }
}
