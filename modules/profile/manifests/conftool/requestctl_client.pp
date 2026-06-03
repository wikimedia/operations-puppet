# SPDX-License-Identifier: Apache-2.0
# @summary profile to install conftool requestctl plugin
# @param conftool_prefix the conftool prefix
class profile::conftool::requestctl_client (
    String $conftool_prefix = lookup('conftool_prefix'),
    Hash[String, String] $api_tokens = lookup('profile::conftool::hiddenparma::api_tokens'),
    Array[String] $admin_groups = lookup('profile::conftool::requestctl_client::admin_groups', { 'default_value' => ['ops'] }),
) {
    require profile::conftool::client

    # Ensure everyone in the admin groups group has their api token in their home directory.
    # If even one user in the groups doesn't have an api token, puppet will fail.
    # While this might seem harsh, it's the only way to ensure people get onboarded correctly.
    $admin_module_path = get_module_path('admin')
    $admin_data = loadyaml("${admin_module_path}/data/data.yaml")['groups']
    $admin_groups.each |$grp| {
        unless $grp in $admin_data {
            fail("${grp}, declared in profile::conftool::requestctl_client::admin_groups, does not exist.")
        }
        $admin_data[$grp]['members'].each |$user| {
            if $user in $api_tokens {
                file { "/home/${user}/.requestctl":
                    ensure  => file,
                    mode    => '0400',
                    owner   => $user,
                    group   => $grp,
                    content => "${api_tokens[$user]}\n",
                }
            } else {
                fail("User '${user}' lacks an api token for HP: please add it in profile::conftool::hiddenparma::api_tokens")
            }
        }
    }
    # A lot of people probably still have the muscle memory of using "sudo" when running requestctl. We need that to keep
    # working. We might want a better solution later.
    file { '/root/.requestctl':
        ensure  => file,
        mode    => '0400',
        owner   => 'root',
        group   => 'root',
        content => "${api_tokens['root']}\n",
    }

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
}
