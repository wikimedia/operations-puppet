# == Class: beta::autoupdater
#
# For host continuously updating MediaWiki core and extensions on the beta
# cluster. This is the lame way to automatically pull any code merged in master
# branches.
class beta::autoupdater {
    include ::beta::config
    require misc::deployment::common_scripts
    include ::beta::mwdeploy_sudo

    $stage_dir = $::beta::config::scap_stage_dir

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

    file { '/usr/local/bin/wmf-beta-mwconfig-update':
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        require => Package['git-core'],
        content => template('beta/wmf-beta-mwconfig-update.erb'),
    }

    file { $stage_dir:
        ensure => directory,
        owner  => 'mwdeploy',
        group  => 'mwdeploy',
        mode   => '0775',
    }

    git::clone { 'operations/mediawiki-config':
        directory => $stage_dir,
        branch    => 'master',
        owner     => 'mwdeploy',
        group     => 'mwdeploy',
        require   => File[$stage_dir],
    }

    git::clone { 'mediawiki/core':
        directory => "${stage_dir}/php-master",
        branch    => 'master',
        owner     => 'mwdeploy',
        group     => 'mwdeploy',
        require   => Git::Clone['operations/mediawiki-config'],
    }

    # Remove the placeholder extension directory of the mediawiki/core
    # checkout so that we can checkout the complete extension repository.
    exec { "/bin/rm -r ${stage_dir}/php-master/extensions":
        refreshonly => true,
        subscribe   => Git::Clone['mediawiki/core'],
        before      => Git::Clone['mediawiki/extensions'],
    }

    git::clone { 'mediawiki/extensions':
        directory          => "${stage_dir}/php-master/extensions",
        branch             => 'master',
        owner              => 'mwdeploy',
        group              => 'mwdeploy',
        recurse_submodules => true,
        timeout            => 1800,
        require            => Git::Clone['mediawiki/core'],
    }
}
