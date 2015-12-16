# = class: scap::l10nupdate
#
# Sets up files and cron required to do l10nupdate
#
# == Parameters:
# [*deployment_group*]
#   User group that will be allowed to read log files. (default: wikidev)
#
# [*run_l10nupdate*]
#   Should l10nupdate be run automatically from cron? (default: false)
#
class scap::l10nupdate(
    $deployment_group = 'wikidev',
    $run_l10nupdate   = false,
) {
    require ::mediawiki::users

    $ensure_l10nupdate_cron = $run_l10nupdate ? {
        true    => 'present',
        default => 'absent',
    }

    # The l10nupdate account is used for updating the localisation files
    # with new interface message translations.

    group { 'l10nupdate':
        ensure => present,
        gid    => 120,
    }

    user { 'l10nupdate':
        ensure     => present,
        gid        => 120,
        shell      => '/bin/bash',
        home       => '/home/l10nupdate',
        managehome => true,
    }

    cron { 'l10nupdate':
        ensure  => $ensure_l10nupdate_cron,
        command => '/usr/local/bin/l10nupdate-1 --verbose >> /var/log/l10nupdatelog/l10nupdate.log 2>&1',
        user    => 'l10nupdate',
        hour    => '2',
        minute  => '0',
    }

    file { '/usr/local/bin/l10nupdate':
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/scap/l10nupdate',
    }
    file { '/usr/local/bin/l10nupdate-1':
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/scap/l10nupdate-1',
    }

    sudo::user { 'l10nupdate':
        user => 'l10nupdate',
        privileges => [
            # Allow l10nupdate user to call sync-l10n as the mwdeploy user.
            # This command is equivalent to a restricted sync-dir call that
            # only syncs l10n cache files followed by a scap-rebuild-cdbs
            # call.
            'ALL = (mwdeploy) NOPASSWD: /srv/deployment/scap/scap/bin/sync-l10n',
            # Allow l10nupdate user to run anything as the unprivledged web
            # user. Needed for mwscript actions and related operations.
            "ALL = (${::mediawiki::users::web}) NOPASSWD: ALL",
        ]
    }

    # T119746: make git fetch happy by setting up git identity
    file { '/home/l10nupdate/.gitconfig':
        ensure => 'present',
        owner  => 'l10nupdate',
        group  => 'l10nupdate',
        mode   => '0644',
        source => 'puppet:///modules/scap/l10nupdate.gitconfig',
    }

    # Make sure the log directory exists and has adequate permissions.
    # It's called l10nupdatelog because /var/log/l10nupdate was used
    # previously so it'll be an existing file on some systems.
    # Also create the dir for the SVN checkouts, and set up log rotation
    file { '/var/log/l10nupdatelog':
        ensure => directory,
        owner  => 'l10nupdate',
        group  => $deployment_group,
        mode   => '0664',
    }
    file { '/var/lib/l10nupdate':
        ensure => directory,
        owner  => 'l10nupdate',
        group  => $deployment_group,
        mode   => '0755',
    }
    file { '/var/lib/l10nupdate/caches':
        ensure => directory,
        owner  => $::mediawiki::users::web,
        group  => $::mediawiki::users::web,
        mode   => '0755',
    }
    file { '/etc/logrotate.d/l10nupdate':
        source => 'puppet:///modules/scap/l10nupdate.logrotate',
        mode   => '0444',
    }
}
