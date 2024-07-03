# SPDX-License-Identifier: Apache-2.0
class profile::kubernetes::deployment_server::mediawiki::mwscript {
    file { '/usr/local/bin/mwscript-k8s':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/profile/kubernetes/deployment_server/mwscript_k8s.py'
    }

    file { '/usr/local/bin/mwscript-cleanup':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/profile/kubernetes/deployment_server/mwscript_cleanup.py'
    }

    systemd::timer::job { 'mwscript-cleanup':
        ensure             => present,
        description        => 'Remove lingering Helm releases from completed maintenance scripts.',
        command            => "/usr/local/bin/mwscript-cleanup --debug ${::site}",
        interval           => {
            start    => 'OnUnitActiveSec',
            interval => '1 day',
        },
        user               => 'www-data',
        monitoring_enabled => true,
        team               => 'ServiceOps'
    }
}
