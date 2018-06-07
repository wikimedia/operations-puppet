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
    $system_members = $gdata['system_members']

    # Be specific with puppet array concatenation, don't
    # want to accidentally concat nil into list of strings.
    # Note: The flatten here isn't strictly necessary since ruby's join does
    # this anyway internally, but let's be pedantic
    if !empty($members) and !empty($system_members) {
        # Ensure both human and system users are members of this group.
        $joined_user_list = join(flatten(concat($members, $system_members)), ',')
    }
    elsif !empty($members) {
        # Else ensure just humans are members of this group.
        $joined_user_list = join(flatten($members), ',')
    }
    elsif !empty($system_members) {
        # Else ensure just system users are members of this group.
        $joined_user_list = join(flatten($system_members), ',')
    }
    # Else both member lists are empty, use $default_member only.
    else {
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
