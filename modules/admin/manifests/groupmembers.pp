# A defined type for managing system group members
#
# === Parameters
#
# [*name*]
#  Group name
#
# [*default_member*]
#  User to be added to a group when explicit members array is empty

define admin::groupmembers(
    $default_member='root',
)
    {

    $gdata = $::admin::data['groups'][$name]
    $members = $gdata['members']

    if !empty($members) {
        # Note: The flatten here isn't strictly necessary since ruby's join does
        # this anyway internally, but let's be pedantic
        $joined_user_list = join(flatten($members),',')
    } else {
        $joined_user_list = $default_member
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
