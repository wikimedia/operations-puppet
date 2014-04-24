# Creates groups, users, and sudo permissions all from yaml for valid passed group name
#
# === Parameters
#
# [*$groups*]
#  Array of valid groups (defined in yaml) to create with associated members
#
# [*$always_groups*]
#  Array of valid groups to always run
#

class admin(
    $groups=[],
    $always_groups=['absent', 'ops'],
)
    {

    $module_path = get_module_path($module_name)
    $data = loadyaml("${module_path}/data/data.yaml") 
    $uinfo = $data['users']
    $users = keys($uinfo)

    #making sure to include always_groups
    $all_groups = split(inline_template("<%= (always_groups+groups).join(',') %>"),',')

    #this custom function eliminates the need for virtual users
    $user_set = unique_users($data, $all_groups)

    file { '/usr/local/bin/user_cleanup.sh':
        ensure => file,
        mode   => '0755',
        source => 'puppet:///modules/admin/user_cleanup.sh',
        before => Exec[user_cleanup],
    }

    file { '/etc/sudoers':
        ensure => file,
        mode   => '0440',
        source => 'puppet:///modules/admin/sudoers',
        tag    => 'sudoers',
    }

    admin::yamlgroup { $all_groups:
        yamlhash => $data,
        before   => Admin::Yamluser[$user_set],
    }

    admin::yamluser { $user_set:
        yamlhash => $data,
        before   => Admin::Groupmembers[$all_groups],
    }

    admin::groupmembers { $all_groups:
        yamlhash => $data,
        before   => Exec[user_cleanup],
    }

    #declarative gotcha: non-defined users can get left behind
    #here we cleanup anyone not in a supplementary group above a certain UID
    exec { "user_cleanup":
        command   => "/usr/local/bin/user_cleanup.sh",
        unless    => "/usr/local/bin/user_cleanup.sh dryrun",
        logoutput => true,
    }
}
