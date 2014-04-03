# == Class: beta::autoupdater
#
# For host continuously updating MediaWiki core and extensions on the beta
# cluster. This is the lame way to automatically pull any code merged in master
# branches.
class beta::autoupdater {

    require misc::deployment::common_scripts
    include ::beta::mwdeploy_sudo

    # Parsoid JavaScript dependencies are updated on beta via npm
    package { 'npm':
        ensure => 'present',
    }

    file { '/usr/local/bin/wmf-beta-autoupdate.py':
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        require => Package['git-core'],
        source  => 'puppet:///modules/beta/wmf-beta-autoupdate.py',
    }
}
