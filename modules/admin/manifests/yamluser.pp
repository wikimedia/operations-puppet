# A defined type for user creation from yaml
#
# === Parameters
#
# [*name*]
#  Yaml user name
#
# [*yamlhash*]
#  Hash with valid user data

define admin::yamluser(
    $yamlhash={},
)
    {

    $uinfo = $yamlhash['users'][$name]

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
