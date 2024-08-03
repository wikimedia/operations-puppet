# SPDX-License-Identifier: Apache-2.0
# This profile sets up an bastion/dev instance in the Toolforge model.
class profile::toolforge::bastion (
    String[1]              $component           = lookup('profile::wmcs::kubeadm::component'),
) {
    if debian::codename::eq('buster') {
        include profile::toolforge::shell_environ
    } else {
        include profile::locales::all

        ensure_packages([
            'emacs-nox',
            'joe',  # T371556
            'neovim',
            'rsync',  # T362679
        ])
    }

    include profile::toolforge::k8s::client

    file { '/bin/disabledtoolshell':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/profile/toolforge/disabledtoolshell',
    }

    # misctools is in the tools aptly repo
    ensure_packages(['misctools'], {
        ensure => latest,
    })

    motd::script { 'bastion-banner':
        ensure => present,
        source => "puppet:///modules/profile/toolforge/40-${::wmcs_project}-bastion-banner.sh",
    }

    if debian::codename::eq('buster') {
        motd::script { 'deprecated-bastion-banner':
            ensure => present,
            source => "puppet:///modules/profile/toolforge/50-${::wmcs_project}-deprecated-bastion-banner.sh",
        }
    }

    package { 'mosh':
        ensure => present,
    }

    $grid_off_script = @("GRIDOFF"/L)
       #!/bin/bash
       echo 'The grid engine has been shut off, for more information see:'
       echo 'https://wikitech.wikimedia.org/wiki/News/Toolforge_Grid_Engine_deprecation'
       exit 1
       | GRIDOFF

    # /usr/local/bin has precedence in $PATH to /usr/bin
    file { [
      '/usr/local/bin/qstat',
      '/usr/local/bin/jsub',
      '/usr/local/bin/crontab',
    ]:
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0655',
        content => $grid_off_script,
    }
}
