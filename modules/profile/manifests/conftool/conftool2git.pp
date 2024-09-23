# SPDX-License-Identifier: Apache-2.0
# @summary This class handles the conftool2git service.
#
# @param conftool2git_address The address of the conftool2git server, in bind_address:port format.
#
# @param ssh_privkey The private key to use for the git clone.
#
# @param pubkey The public key to add to the authorized_keys file.
#
class profile::conftool::conftool2git (
    String $conftool2git_address = lookup('profile::conftool2git::address', { 'default_value' => '0.0.0.0:1312' }),
    Sensitive[String] $ssh_privkey = lookup('profile::conftool2git::ssh_privkey'),
    String $pubkey = lookup('profile::conftool2git::pubkey'),
) {
    # We definitely need conftool client to be configured.
    require profile::conftool::client

    # Install the python3-conftool-conftool2git package
    ensure_packages(['python3-conftool-conftool2git'])

    $ctgit_user_home = '/var/lib/conftool2git'
    # Create the system user.
    systemd::sysuser { 'conftool2git':
        ensure   => present,
        shell    => '/bin/bash',
        home_dir => $ctgit_user_home,
    }

    systemd::service { 'conftool2git':
        ensure               => present,
        content              => template('profile/conftool/conftool2git_service.erb'),
        restart              => false, # We don't want to restart the service during a random puppet run, but control when that happens.
        monitoring_enabled   => true,
        monitoring_notes_url => 'https://wikitech.wikimedia.org/wiki/Conftool2git',
        monitoring_critical  => false,
    }

    $parsed_addr = split($conftool2git_address, /:/)

    ## Create the conftool2git repository ##
    # In this case, fetching the servers from puppetdb does not create a race
    # condition, because when the first server is installed, the repository is
    # created empty and the post-commit hook is not installed. When the second server
    # is installed, it will now see there's a server already installed and source the repository
    # from it. Then the post-commit hook is installed.
    $servers = wmflib::puppetdb_query(
        'nodes[certname] { resources { type = "Class" and title = "Profile::Conftool2git" } order by certname}'
    ).map |$node| { $node['certname'] }

    git::replicated_local_repo { 'conftool/auditlog':
        servers      => $servers,
        user         => 'conftool2git',
        user_homedir => $ctgit_user_home,
        ssh_pubkey   => $pubkey,
        ssh_privkey  => $ssh_privkey,
    }

    file { '/etc/default/conftool2git':
        ensure  => file,
        content => template('profile/conftool/conftool2git_default.erb'),
        mode    => '0444',
        notify  => Service['conftool2git'],
    }
}
