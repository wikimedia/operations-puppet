# A defined type for managing system group members
#
# === Parameters
#
# [*name*]
#  Group name
#
# [*phash*]
#  Hash that contains valid group data
#
# [*default_member*]
#  User to be added to a group when explicit members array is empty

define admin::groupmembers(
    $phash={},
    $default_member='root',
)
    {

    $gdata = $phash['groups'][$name]
    $members = $gdata['members']

    if !empty($members) {
        $joined_user_list = join($members,',')
    } else {

    $joined_user_list = $title? {
        'all-users' => keys($phash['users']),
        default     => $default_member,
        }
    }

    if has_key($gdata, 'posix_name') {
        $group_name = $gdata['posix_name']
    } else {
        $group_name = $name
    }

    #this list is inclusive.  anyone not defined is removed.
    #check for group existence and if so compare current users
    $group_nonexistent="getent group ${group_name} | xargs test -z"
    $members_match="getent group ${group_name} | cut -d ':' -f 4 | grep -E ^${joined_user_list}$"
    exec { "${group_name}_ensure_members":
        command   => "/usr/bin/gpasswd ${group_name} -M ${joined_user_list}",
        path      => '/usr/bin:/bin',
        unless    => "${group_nonexistent} || ${members_match}",
        logoutput => true,
    }
}
