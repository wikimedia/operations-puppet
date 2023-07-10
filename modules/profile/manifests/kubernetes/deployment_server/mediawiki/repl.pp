# SPDX-License-Identifier: Apache-2.0
class profile::kubernetes::deployment_server::mediawiki::repl {
    file { '/usr/local/bin/mw-debug-repl':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/profile/kubernetes/deployment_server/mw-debug-repl.sh'
    }

    sudo::group { 'deployment-mw-debug-repl':
        ensure     => present,
        group      => 'deployment',
        privileges => [
            'ALL = NOPASSWD: /usr/local/bin/mw-debug-repl'
        ]
    }
}
