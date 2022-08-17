# @ summary Creates groups, users, and sudo permissions from yaml for valid passed group name
#
#
# @param groups Array of valid groups (defined in yaml) to create with associated members
# @param groups_no_ssh
#    Array of valid groups (defined in yaml) to create with associated members,
#    with the constraint that no ssh key for their users is deployed.
# @param always_groups Array of valid groups to always run
# @param managehome if true puppet will use `useradd -m` when creating users.
#   This is useful if you want to make use of the /etc/skel directory to create additional
#   files and directories.  For example on people1001 its nice to ensure all user have
#   ~/public_html
# @param managelingering if true puppet will enable lingering for all kerberos enabled users.
#   Default false.
# @param additional_shells list of addtional shells to install

class admin(
    Array[String[1]] $groups            = [],
    Array[String[1]] $groups_no_ssh     = [],
    Array[String[1]] $always_groups     = ['absent', 'ops', 'wikidev', 'ops-adm-group', 'sre-admins'],
    Boolean          $managehome        = false,
    Boolean          $managelingering   = false,
    Array[String]    $additional_shells = ['zsh'],
)
{
    ensure_packages($additional_shells)
    $module_path = get_module_path($module_name)
    $base_data = loadyaml("${module_path}/data/data.yaml")

    $uinfo = $base_data['users']
    $users = $uinfo.keys

    # Fill the all-users group with all active users
    $real_users = $uinfo.filter |$user, $config| {
        $config['ensure'] == 'present' and (!('system' in $config) or $config['system'] == false)
    }.keys
    $data = deep_merge($base_data, {'groups' => {'all-users' => {'members' => $real_users}}})

    $system_users = $uinfo.filter |$user, $config| { $config['system'] == true }.keys
    $system_groups = $data['groups'].filter |$group, $config| { $config['system'] == true }.keys

    # making sure to include always_groups
    # These are groups containing users with SSH access
    $regular_groups = $always_groups + $groups

    # These are all groups configured
    $all_groups = $regular_groups + $groups_no_ssh + $system_groups

    # Note: the unique_users() custom function eliminates the need for virtual users.

    # List of users with SSH access
    $users_set_ssh = admin::unique_users($regular_groups)

    # List of users without SSH access
    # Note: since a user may be listed among groups in $groups
    # and at the same time groups in $groups_no_ssh,
    # we need to make sure that the two sets don't overlap.
    $users_set_nossh = admin::unique_users($groups_no_ssh).filter |$user| { !($user in $users_set_ssh) }

    # List of Kerberos enabled users
    $users_krb_enabled = admin::kerberos_users($data)

    file { '/usr/local/sbin/enforce-users-groups':
        ensure => file,
        mode   => '0555',
        source => 'puppet:///modules/admin/enforce-users-groups.sh',
    }

    admin::hashgroup { $all_groups: }

    admin::hashuser { $users_set_ssh:
        ensure_ssh_key => true,
    }

    admin::hashuser { $users_set_nossh:
        ensure_ssh_key => false,
    }

    admin::hashuser { $system_users:
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

    # For hosts where we allow user lingering, create the directory to hold linger records
    # Then create an empty file in that directory for each kerberos enabled user account
    if $managelingering {
        file { '/var/lib/systemd/linger':
            ensure => directory,
            mode   => '0555',
            owner  => 'root',
            group  => 'root',
        }
        admin::userlinger { $users_krb_enabled: }
    }
}
