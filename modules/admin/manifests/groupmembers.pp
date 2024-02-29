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
    String $default_member = 'root',
) {


    $gdata = $::admin::data['groups'][$name]
    $group_name = pick($gdata['posix_name'], $name)
    $members = Array($gdata['members'], true)
    $system_members = Array($gdata['system_members'], true)

    $user_list = ($members + $system_members).filter |$user| { $user =~ NotUndef }
    $joined_user_list = $user_list.empty ? {
        true    => $default_member,
        default => $user_list.flatten().join(','),
    }


    # this list is inclusive.  anyone not defined is removed.
    # check for group existence and if so compare current users
    $group_nonexistent="getent group ${group_name} | xargs test -z"
    $members_match="getent group ${group_name} | cut -d ':' -f 4 | grep -E ^${joined_user_list}$"
    exec { "${group_name}_ensure_members":
        command   => "/usr/bin/gpasswd ${group_name} -M ${joined_user_list}",
        path      => '/usr/bin:/bin',
        unless    => "${group_nonexistent} || ${members_match}",
        logoutput => true,
        require   => User[$user_list],
    }
}
