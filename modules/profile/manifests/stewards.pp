# SPDX-License-Identifier: Apache-2.0
# special VM for stewards (T344164)
class profile::stewards (
    Stdlib::Unixpath $repo_dir = lookup('profile::stewards::repo_dir', {default_value => '/srv/repos'}),
    Stdlib::Unixpath $conf_dir = lookup('profile::stewards::conf_dir', {default_value => '/etc/steward-onboarder'}),
    Stdlib::Unixpath $export_dir = lookup('profile::stewards::export_dir', {default_value => '/srv/exports'}),
    Stdlib::Unixpath $userdb_dir = lookup('profile::stewards::userdb_dir', {default_value => "${repo_dir}/users-db"}),
    Stdlib::Unixpath $onboarding_system_dir = lookup('profile::stewards::onboarding_system_dir', {default_value => "${repo_dir}/onboarding-system"}),
    String $gitlab_api_token = lookup('profile::stewards::gitlab_api_token', {default_value => 'snakeoil'}),
    String $group_owner = lookup('profile::stewards::group_owner', {default_value => 'stewards-users'}),
    Stdlib::Fqdn $lists_primary_host = lookup('lists_primary_host', {'default_value' => undef}),
){

    # T344164#9314186, T369322
    ensure_packages(['python3-click', 'python3-requests-oauthlib', 'python3-phabricator'])

    # conf dir and repo dir not writable
    wmflib::dir::mkdir_p([$conf_dir, $repo_dir], {
        owner => 'root',
        group => $group_owner,
        mode  => '0755',
    })

    # export dir group writable
    wmflib::dir::mkdir_p($export_dir, {
        owner => 'root',
        group => $group_owner,
        mode  => '0775',
    })

    # pull onboarding application from gitlab and create the config
    git::clone { 'repos/stewards/onboarding-system':
        ensure    => 'present',
        source    => 'gitlab',
        group     => $group_owner,
        shared    => true,
        directory => $onboarding_system_dir,
    }

    file { "${conf_dir}/steward-onboarder.yaml":
        ensure  => 'present',
        content => template('profile/stewards/steward-onboarder.yaml.erb'),
    }

    git::systemconfig { 'safe.directory-onboarding_system_dir':
        settings => {
            'safe' => {
                'directory' => $onboarding_system_dir
            }
        }
    }

    # create a local-only repo to hold private onboarding app data
    file { $userdb_dir:
        ensure => directory,
        owner  => 'root',
        group  => $group_owner,
        mode   => '2775',
    }

    git::systemconfig { 'safe.directory-userdb_dir':
        settings => {
            'safe' => {
                'directory' => $userdb_dir
            }
        }
    }

    exec { "${userdb_dir} git init":
        command => '/usr/bin/git init',
        user    => 'root',
        group   => $group_owner,
        cwd     => $userdb_dir,
        creates => "${userdb_dir}/.git",
        require => File[$userdb_dir],
    }

    # let lists primary host sync data from the export_dir
    # passing an empty string to address = listens on IPv6 as well, not just 0.0.0.0
    class { 'rsync::server':
        address => '',
    }

    rsync::server::module { 'steward-data-export-dir':
        ensure        => present,
        comment       => "${export_dir} to lists servers",
        read_only     => 'yes',
        path          => $export_dir,
        hosts_allow   => [$lists_primary_host, 'lists.wikimedia.org'], # Temporary fix until we get new service IPs for lists1004
        auto_firewall => true,
        require       => [
            File[$export_dir],
        ],
    }

}
