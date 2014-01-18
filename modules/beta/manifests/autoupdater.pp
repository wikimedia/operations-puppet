# == Class: beta::autoupdater
#
# For host continuously updating MediaWiki core and extensions on the beta
# cluster. This is the lame way to automatically pull any code merged in master
# branches.
class beta::autoupdater {

    require misc::deployment::common_scripts

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

    # Make sure wmf-beta-autoupdate can run the l10n updater as l10nupdate
    sudo_user { 'mwdeploy' :
        privileges => [
            'ALL = (l10nupdate) NOPASSWD:/usr/local/bin/mw-update-l10n',
            'ALL = (l10nupdate) NOPASSWD:/usr/local/bin/mwscript',
            'ALL = (l10nupdate) NOPASSWD:/usr/local/bin/refreshCdbJsonFiles',
            # Some script running as mwdeploy explicily use "sudo -u mwdeploy"
            # which makes Ubuntu to request a password. The following rule
            # make sure we are not going to ask the password to mwdeploy when
            # it tries to identify as mwdeploy.
            'ALL = (mwdeploy) NOPASSWD: ALL',

            # mergeMessageFileList.php is run by mw-update-l10n as the apache user
            # since https://gerrit.wikimedia.org/r/#/c/44548/
            # Let it runs mwscript and others as apache user.
            'ALL = (apache) NOPASSWD: ALL',
        ]
    }
}
