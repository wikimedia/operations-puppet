# A defined type for user creation from hash
#
# === Parameters
#
# [*name*]
#  Hash user name
#
# [*phash*]
#  Hash with valid user data

define admin::hashuser(
    $phash={},
)
    {

    $uinfo = $phash['users'][$name]

    if has_key($uinfo, 'gid') {
        $group_id = $uinfo['gid']
    }
    else {
        $group_id = $uinfo['uid']
    }

    if has_key($uinfo, 'ssh_keys') {
        $key_set = $uinfo['ssh_keys']
    }
    else {
        $key_set = []
    }

    admin::user { $name:
        ensure      => $uinfo['ensure'],
        uid         => $uinfo['uid'],
        gid         => $group_id,
        groups      => $uinfo['groups'],
        comment     => $uinfo['realname'],
        shell       => $uinfo['shell'],
        privs       => $uinfo['privs'],
        ssh_keys    => $key_set,
   }
}
