# Creates groups, users, and sudo permissions all from yaml for valid passed group name
#
# === Parameters
#
# [*$groups*]
#  Array of valid groups (defined in yaml) to create with associated members
#  Do not specify when using $all_group_users
#
# [*$always_groups*]
#  Array of valid groups to always run
#
# [*$all_group_users*]
#  Boolean that indicates all active users should be applied
#
#  NOTE: This does not come with any group permissions on its own
#

class admin(
    $groups          = [],
    $all_group_users = false,
    $always_groups   = ['absent', 'ops', 'wikidev'],
)
{
    include sudo

    $module_path = get_module_path($module_name)
    $data = loadyaml("${module_path}/data/data.yaml")
    $uinfo = $data['users']
    $users = keys($uinfo)

    if ($all_group_users) and !empty($groups) {
        fail('Do not specify groups using $all_group_users')
    }

    if ($all_group_users) {
        $ginfo = $data['groups']
        $grouplist = keys($ginfo)

        # All users defined in at least one group
        $user_set = unique_users($data, $grouplist)
    }
    else {
        $user_set = unique_users($data, $applied_groups)
    }

    # making sure to include always_groups
    $applied_groups = concat($always_groups, $groups)

    file { '/usr/local/sbin/enforce-users-groups':
        ensure => file,
        mode   => '0555',
        source => 'puppet:///modules/admin/enforce-users-groups.sh',
    }

    admin::hashgroup { $applied_groups:
        phash  => $data,
        before => Admin::Hashuser[$user_set],
    }

    admin::hashuser { $user_set:
        phash  => $data,
        before => Admin::Groupmembers[$applied_groups],
    }

    admin::groupmembers { $applied_groups:
        phash  => $data,
        before => Exec['enforce-users-groups-cleanup'],
    }

    # Declarative gotcha: non-defined users can get left behind
    # Here we cleanup anyone not in a supplementary group above a certain UID
    exec { 'enforce-users-groups-cleanup':
        command   => '/usr/local/sbin/enforce-users-groups',
        unless    => '/usr/local/sbin/enforce-users-groups dryrun',
        logoutput => true,
    }
}
