# SPDX-License-Identifier: Apache-2.0
# special VM for stewards (T344164)
class profile::stewards (
){
    # T344164#9314186
    ensure_packages(['python3-click', 'python3-requests-oauthlib'])

    $repo_dir = '/srv/repos'
    wmflib::dir::mkdir_p($repo_dir)

    git::clone { 'repos/stewards/onboarding-system':
        ensure    => 'present',
        source    => 'gitlab',
        group     => 'wikidev',
        shared    => true,
        directory => "${repo_dir}/onboarding-system",
    }
}
