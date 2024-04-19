# SPDX-License-Identifier: Apache-2.0
# special VM for stewards (T344164)
class profile::stewards (
){
    # T344164#9314186
    ensure_packages(['python3-click', 'python3-requests-oauthlib'])

    $repo_dir = '/srv/repos'
    $conf_dir = '/etc/steward-onboarder'
    $export_dir = '/srv/exports'
    $userdb_dir = "${repo_dir}/users-db"

    $group_owner = 'stewards-users'

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

    # pull application from gitlab and create the config
    git::clone { 'repos/stewards/onboarding-system':
        ensure    => 'present',
        source    => 'gitlab',
        group     => $group_owner,
        shared    => true,
        directory => "${repo_dir}/onboarding-system",
    }

    file { "${conf_dir}/steward-onboarder.yaml":
        ensure => 'present',
        source => 'puppet:///modules/profile/stewards/steward-onboarder.yaml',
    }

    # create a local-only repo to hold private app data
    file { $userdb_dir:
        ensure  => directory,
        owner   => 'root',
        group   => $group_owner,
        mode    => '2775',
        recurse => true,
    }

    exec { "${userdb_dir} git init":
        command => '/usr/bin/git init',
        user    => 'root',
        group   => $group_owner,
        cwd     => $userdb_dir,
        creates => "${userdb_dir}/.git",
        require => File[$userdb_dir],
    }
}
