# SPDX-License-Identifier: Apache-2.0
# @summary This class handles the conftool2git service.
#
# @param conftool2git_address The address of the conftool2git server, in bind_address:port format.
#
# @param ssh_privkey The private key to use for the git clone.
#
# @param pubkey The public key to add to the authorized_keys file.
#
# @param active_host The active host to use for the conftool2git service.
class profile::conftool::conftool2git (
    String $conftool2git_address = lookup('profile::conftool2git::address', { 'default_value' => '0.0.0.0:1312' }),
    Sensitive[String] $ssh_privkey = lookup('profile::conftool2git::ssh_privkey'),
    String $pubkey = lookup('profile::conftool2git::pubkey'),
    Stdlib::Fqdn $active_host = lookup('profile::conftool2git::active_host'),
) {
    # We definitely need conftool client to be configured.
    require profile::conftool::client

    # Install the python3-conftool-conftool2git package
    ensure_packages(['python3-aiohttp', 'python3-conftool-conftool2git'])

    $ctgit_user_home = '/var/lib/conftool2git'
    # Create the system user.
    systemd::sysuser { 'conftool2git':
        ensure   => present,
        shell    => '/bin/bash',
        home_dir => $ctgit_user_home,
    }

    file { $ctgit_user_home:
        ensure  => directory,
        owner   => 'conftool2git',
        group   => 'conftool2git',
        mode    => '0755',
        require => Systemd::Sysuser['conftool2git'],
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
    $is_active_host = $facts['networking']['fqdn'] == $active_host
    $service_ensure = $is_active_host.bool2str('present', 'absent')

    systemd::service { 'conftool2git':
        ensure               => $service_ensure,
        content              => template('profile/conftool/conftool2git_service.erb'),
        restart              => false, # We don't want to restart the service during a random puppet run, but control when that happens.
        monitoring_enabled   => true,
        monitoring_notes_url => 'https://wikitech.wikimedia.org/wiki/Conftool2git',
        monitoring_critical  => false,
    }

    if $is_active_host {
        # We only want to run conftool2git on the active host.
        ferm::service { 'conftool2git':
            proto  => 'tcp',
            port   => $parsed_addr[1],
            srange => '$DOMAIN_NETWORKS',
        }
    }
}
