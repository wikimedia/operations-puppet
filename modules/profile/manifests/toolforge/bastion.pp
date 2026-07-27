# SPDX-License-Identifier: Apache-2.0
# This profile sets up an bastion/dev instance in the Toolforge model.
class profile::toolforge::bastion (
    String[1]              $component           = lookup('profile::wmcs::kubeadm::component'),
) {
    include profile::locales::all

    ensure_packages([
        'emacs-nox',
        'joe',  # T371556
        'neovim',
        'redis-tools',  # T410102
        'rsync',  # T362679
    ])

    include profile::toolforge::k8s::client

    file { '/bin/disabledtoolshell':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/profile/toolforge/disabledtoolshell',
    }

    motd::script { 'bastion-banner':
        ensure => present,
        source => "puppet:///modules/profile/toolforge/40-${::wmcs_project}-bastion-banner.sh",
    }

    package { 'mosh':
        ensure => present,
    }

    file { [
      '/usr/local/bin/qstat',
      '/usr/local/bin/jsub',
      '/usr/local/bin/crontab',
    ]:
        ensure  => absent,
    }
}
