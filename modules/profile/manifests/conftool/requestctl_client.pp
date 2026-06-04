# SPDX-License-Identifier: Apache-2.0
# @summary profile to install conftool requestctl plugin
# @param conftool_prefix the conftool prefix
# @param root_token the root token to use for requestctl
# @param admin_groups the groups whose members should have requestctl credentials installed in their home directories. Defaults to ['ops'].
class profile::conftool::requestctl_client (
    String $conftool_prefix = lookup('conftool_prefix'),
    String $root_token = lookup('profile::conftool::hiddenparma::root_token'),
    Array[String] $admin_groups = lookup('profile::conftool::requestctl_client::admin_groups', { 'default_value' => ['ops'] }),
) {
    require profile::conftool::client

    # This is a copy of the file contained in the scripts/ directory of the
    # HIDDENPARMA repository:
    # https://gitlab.wikimedia.org/repos/sre/hiddenparma/-/blob/main/scripts/requestctl_cli.py
    file { '/usr/bin/requestctl':
        ensure => file,
        mode   => '0755',
        source => 'puppet:///modules/profile/conftool/requestctl_cli.original.py',
    }
    file { '/usr/local/bin/requestctl-checkip':
        ensure => file,
        owner  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/profile/conftool/requestctl_checkip.py',
    }

    ## Credentials management

    # Ensure everyone in the admin groups group has their api token in their home directory.
    # If even one user in the groups doesn't have an api token, puppet will fail.
    # While this might seem harsh, it's the only way to ensure people get onboarded correctly.
    $admin_module_path = get_module_path('admin')
    $admin_data = loadyaml("${admin_module_path}/data/data.yaml")
    $admin_group_data = $admin_data['groups']

    $admin_users = $admin_data['users']
    # Create a set of shell username => realname pairs, to use in downloading the credentials.
    $shell_name_to_username = $admin_groups.reduce([]) |$acc, $grp| {
        unless $grp in $admin_group_data {
            fail("${grp}, declared in profile::conftool::requestctl_client::admin_groups, does not exist.")
        }
        $admin_group_data[$grp]['members'] + $acc
    }.unique().map |$user| {
        unless $user in $admin_users {
            fail("${user}, a member of an admin group declared in profile::conftool::requestctl_client::admin_groups, does not exist.")
        }
        #TODO: check if the user is a system user and skip it.
        [$user, $admin_users[$user]['realname']]
    }.reduce({}) |$acc, $pair| {
        $acc + $pair
    }
    file { '/etc/conftool/requestctl_credentials.json':
        ensure  => file,
        mode    => '0600',
        owner   => 'root',
        group   => 'root',
        content => to_json($shell_name_to_username),
    }
    # A lot of people probably still have the muscle memory of using "sudo" when running requestctl. We need that to keep
    # working. We might want a better solution later.
    file { '/root/.requestctl':
        ensure  => file,
        mode    => '0400',
        owner   => 'root',
        group   => 'root',
        content => "${root_token}\n",
    }

    file { '/usr/local/bin/generate-requestctl-credentials':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0544',
        source => 'puppet:///modules/profile/conftool/generate_requestctl_credentials.py',
    }

    systemd::timer::job { 'requestctl-credential-refresh':
        ensure      => present,
        description => 'Refresh requestctl API credentials for all users',
        interval    => { 'start' => 'OnUnitInactiveSec', 'interval' => '1h' },
        command     => '/usr/local/bin/generate-requestctl-credentials /etc/conftool/requestctl_credentials.json',
        user        => 'root',
        group       => 'root',
        require     => File['/etc/conftool/requestctl_credentials.json', '/usr/local/bin/generate-requestctl-credentials'],
    }
}
