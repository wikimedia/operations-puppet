# SPDX-License-Identifier: Apache-2.0
# == Class: beta::autoupdater
#
# Update MediaWiki based on a timer.
#
# === Parameters:
# [*update_interval*]
#   How often to run the update script as a systemd timer OnCalendar interval
#
# [*run_updater*]
#   Run the update script on this node?
#
# [*apache_fqdn*]
#   Name of vhost responsible for exposing logs to the world
#
# [*alert_on_failure*]
#   Send email alerts when the update job fails
#
# [*notify_email*]
#   Email address to notify when alert_on_failure=true and job fails
#
# [*max_runtime_seconds*]
#   Kill the update job if it runs longer than this many seconds, so a stuck
#   run cannot block subsequent runs indefinitely
#
class beta::autoupdater (
    String        $update_interval,
    Boolean       $run_updater,
    String        $apache_fqdn,
    Boolean       $alert_on_failure,
    Stdlib::Email $notify_email,
    Integer       $max_runtime_seconds,
) {
    $stage_dir = '/srv/mediawiki-staging'
    $log_dir = '/srv/beta-update-logs'
    $runtime_user = 'jenkins-deploy'
    $runtime_group = 'wikidev'
    $active_ensure = $run_updater.bool2str('present', 'absent')

    # T256168: script to coordinate updating Beta's code, config, and databases
    file { '/usr/local/bin/wmf-beta-update-all':
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        content => template('beta/wmf-beta-update-all.sh.erb'),
    }

    file { $log_dir:
      ensure => directory,
      owner  => $runtime_user,
      group  => 'root',
      mode   => '0655'
    }

    httpd::site { 'beta-autoupdater':
        content => template('beta/apache-vhost.erb'),
        require => File[$log_dir],
    }

    file { '/usr/local/bin/wmf-beta-update-databases.py':
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/beta/wmf-beta-update-databases.py',
    }

    # Convenience: tail the most recent autoupdater log in $log_dir
    file { '/usr/local/bin/tail-beta-update-logs':
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        content => template('beta/tail-beta-update-logs.sh.erb'),
    }

    systemd::timer::job { 'wmf-beta-update-all':
        ensure                  => $active_ensure,
        description             => 'Update MediaWiki code, config, and databases',
        user                    => $runtime_user,
        command                 => '/usr/local/bin/wmf-beta-update-all',
        send_mail               => $alert_on_failure,
        send_mail_only_on_error => true,
        send_mail_to            => $notify_email,
        # Sender address must be a valid Cloud VPS host or mx-out will reject
        # FIXME: 'BETA UPDATER <noreply@...>' would be nicer, but the
        # Stdlib::Email validator wants a bare address.
        send_mail_from          => "noreply@${facts['networking']['fqdn']}",
        # T256168: a oneshot service is considered "starting" for the whole
        # duration of ExecStart, so TimeoutStartSec (rendered from this) caps
        # the total run time and kills a stuck update before the next fires.
        max_runtime_seconds     => $max_runtime_seconds,
        interval                => {
            'start'    => 'OnCalendar',
            'interval' => $update_interval,
        },
        require                 => [
            File[$log_dir],
            File['/usr/local/bin/wmf-beta-update-all'],
            File['/usr/local/bin/wmf-beta-update-databases.py'],
        ],
    }

    systemd::timer::job { 'beta-autoupdater-prune-stale-logs':
        ensure      => $active_ensure,
        description => 'Prune stale autoupdater logs',
        user        => $runtime_user,
        command     => "/usr/bin/find ${log_dir} -type f -mtime +3 -delete",
        interval    => { 'start' => 'OnCalendar', 'interval' => 'daily' },
        require     => File[$log_dir],
    }

    #
    # Bootstrapping for our "php-master" deployment branch
    #
    git::clone { 'beta-mediawiki-core':
        directory => "${stage_dir}/php-master",
        origin    => 'https://gerrit.wikimedia.org/r/mediawiki/core.git',
        branch    => 'master',
        owner     => $runtime_user,
        group     => $runtime_group,
        require   => Git::Clone['operations/mediawiki-config'],
    }

    # TODO: is this still needed?
    git::clone { 'beta-portal':
        directory => "${stage_dir}/portal-master",
        origin    => 'https://gerrit.wikimedia.org/r/wikimedia/portals.git',
        branch    => 'master',
        owner     => $runtime_user,
        group     => $runtime_group,
        require   => Git::Clone['operations/mediawiki-config'],
    }
    file { "${stage_dir}/docroot/wwwportal/portal-master":
        ensure => 'link',
        target => '../../portal-master/prod',
    }

    # Remove the placeholder extension directory of the mediawiki/core
    # checkout so that we can checkout the complete extension repository.
    exec { "/bin/rm -r ${stage_dir}/php-master/extensions":
        refreshonly => true,
        subscribe   => Git::Clone['beta-mediawiki-core'],
        # In case Git::Clone["beta-mediawiki-core"] has some parameter change
        # it will refresh this exec and we do not need to needlessly remove
        # exensions if they are already there.
        unless      => "/usr/bin/test -d \"${stage_dir}/php-master/extensions/.git\"",
        before      => Git::Clone['beta-mediawiki-extensions'],
    }

    git::clone { 'beta-mediawiki-extensions':
        directory          => "${stage_dir}/php-master/extensions",
        origin             => 'https://gerrit.wikimedia.org/r/mediawiki/extensions.git',
        branch             => 'master',
        owner              => $runtime_user,
        group              => $runtime_group,
        recurse_submodules => true,
        timeout            => 1800,
        require            => Git::Clone['beta-mediawiki-core'],
    }

    # MediaWiki core has a /skins/ directory causing git clone to refuse
    # cloning mediawiki/skins.git in the existing repository. Instead use git
    # init.

    $mw_skins_dest = "${stage_dir}/php-master/skins"
    $mw_skins_git_url = 'https://gerrit.wikimedia.org/r/mediawiki/skins.git'

    exec { 'beta_mediawiki_skins_git_init':
        command => "/usr/bin/git init ${mw_skins_dest}",
        user    => $runtime_user,
        group   => $runtime_group,
        creates => "${mw_skins_dest}/.git",
        require => Git::Clone['beta-mediawiki-core'],
        notify  => Exec['beta_mediawiki_skins_git_remote_add'],
    }
    exec { 'beta_mediawiki_skins_git_remote_add':
        command     => "/usr/bin/git remote add origin ${mw_skins_git_url}",
        user        => $runtime_user,
        group       => $runtime_group,
        cwd         => $mw_skins_dest,
        refreshonly => true,
    }

    git::clone { 'beta-mediawiki-skins':
        directory          => $mw_skins_dest,
        origin             => 'https://gerrit.wikimedia.org/r/mediawiki/skins.git',
        branch             => 'master',
        owner              => $runtime_user,
        group              => $runtime_group,
        recurse_submodules => true,
        # Needs to be initialized manually since skins dir exists
        require            => Exec['beta_mediawiki_skins_git_init'],
    }

    git::clone { 'mediawiki/vendor':
        directory => "${stage_dir}/php-master/vendor",
        branch    => 'master',
        owner     => $runtime_user,
        group     => $runtime_group,
        require   => Git::Clone['beta-mediawiki-core'],
    }

    #
    # Legacy cleanup
    #
    file { '/usr/local/bin/wmf-beta-autoupdate.py':
        ensure => absent,
    }
    file { '/usr/local/bin/wmf-beta-mwconfig-update':
        ensure => absent,
    }

}
