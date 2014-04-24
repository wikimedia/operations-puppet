# A defined type for managing system group members
#
# === Parameters
#
# [*name*]
#  Group name
#
# [*yamlhash*]
#  Gash that contains valid group data
#
# [*default_member*]
#  User to be added to a group when explicit members array is empty

define admin::groupmembers(
    $yamlhash={},
    $default_member='root',
)
    {
    include admin

    $gdata = $yamlhash['groups'][$name]
    $members = $gdata['members']

    if !empty($members) {
        $joined_user_list = join($members,",")
    }
    else {
        $joined_user_list = $default_member
    }

    #this list is inclusive.  anyone not defined is removed.
    #check for group existence and if so compare current users
    $group_nonexistent="getent group ${name} | xargs test -z"
    $members_match="getent group ${name} | cut -d ':' -f 4 | grep -E ^${joined_user_list}$"
    exec { "${name}_ensure_members":
        command   => "/usr/bin/gpasswd ${name} -M ${joined_user_list}",
        path      => "/usr/bin:/bin",
        unless    => "$group_nonexistent || $members_match",
        logoutput => true,
    }

}
