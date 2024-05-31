# SPDX-License-Identifier: Apache-2.0
# @summary class to set up addtional aspects of the git private repo
class profile::puppetserver::git::private (
) {
    include profile::puppetserver::git
    $repo_url = "${profile::puppetserver::git::basedir}/private"
    ensure_packages(['yamllint'])
    file { '/etc/puppet/yamllint.yaml':
        ensure => file,
        source => 'puppet:///modules/puppetmaster/git/yamllint.yaml',
    }
    file { '/usr/local/bin/git_ssh_wrapper.sh':
        ensure => file,
        source => 'puppet:///modules/profile/puppetserver/gitprivate/git_ssh_wrapper.sh',
        mode   => '0555',
    }
}
