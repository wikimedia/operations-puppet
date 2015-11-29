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
    $ensure_l10nupdate_cron = $run_l10nupdate ? {
        true    => 'present',
        default => 'absent',
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

    # Allow l10nupdate user to call sync-l10n as the mwdeploy user.
    # This command is equivalent to a restricted sync-dir call that only syncs
    # l10n cache files followed by a scap-rebuild-cdbs call.
    sudo::user { 'l10nupdate-sync':
        user => 'l10nupdate',
        privileges => [
            'ALL = (mwdeploy) NOPASSWD: /srv/deployment/scap/scap/bin/sync-l10n',
        ]
    }

    # l10nupdate's ssh key is no longer needed due to the introduction of the
    # sync-l10n scap script.
    # TODO: remove after ssh key is removed from all hosts
    file { '/home/l10nupdate/.ssh/id_rsa':
        ensure => 'absent',
    }
    file { '/home/l10nupdate/.ssh/id_rsa.pub':
        ensure => 'absent',
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
