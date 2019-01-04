# Creates groups, users, and sudo permissions all from yaml for valid passed group name
#
# === Parameters
#
# [*$groups*]
#  Array of valid groups (defined in yaml) to create with associated members
#
# [*$groups_no_ssh*]
#  Array of valid groups (defined in yaml) to create with associated members,
#  with the constraint that no ssh key for their users is deployed.
#
# [*$always_groups*]
#  Array of valid groups to always run
#

class admin(
    $groups=[],
    $groups_no_ssh=[],
    $always_groups=['absent', 'ops', 'wikidev', 'ops-adm-group'],
)
{
    include ::sudo

    $module_path = get_module_path($module_name)
    $base_data = loadyaml("${module_path}/data/data.yaml")
    # Fill the all-users group with all active users
    $data = add_all_users($base_data)

    $uinfo = $data['users']
    $users = keys($uinfo)

    #making sure to include always_groups
    # These are groups containing users with SSH access
    $regular_groups = concat($always_groups, $groups)
    # These are all groups configured
    $all_groups = concat($regular_groups, $groups_no_ssh)

    # Note: the unique_users() custom function eliminates the need for virtual users.

    # List of users with SSH access
    $users_set_ssh = unique_users($data, $regular_groups)

    # List of users without SSH access
    # Note: since a user may be listed among groups in $groups
    # and at the same time groups in $groups_no_ssh,
    # we need to make sure that the two sets don't overlap.
    $users_set_nossh = unique_users($data, $groups_no_ssh).filter |$user| { !($user in $users_set_ssh) }

    file { '/usr/local/sbin/enforce-users-groups':
        ensure => file,
        mode   => '0555',
        source => 'puppet:///modules/admin/enforce-users-groups.sh',
    }

    admin::hashgroup { $all_groups:
        before => [
            Admin::Hashuser[$users_set_ssh],
            Admin::Hashuser[$users_set_nossh],
        ],
    }

    admin::hashuser { $users_set_ssh:
        ensure_ssh_key => true,
    }

    admin::hashuser { $users_set_nossh:
        ensure_ssh_key => false,
    }

    admin::groupmembers { $all_groups:
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
