# mediawiki maintenance server
class profile::mediawiki::maintenance {
    # In order to be able to use the conftool-aware wrapper, we need to access
    # such data easily (on disk).
    require ::profile::conftool::state

    # httpd for noc.wikimedia.org
    class { '::httpd':
        modules => ['rewrite', 'headers'],
    }

    # Deployment
    include ::scap::scripts

    file { $::mediawiki::scap::mediawiki_staging_dir:
        ensure => link,
        target => '/srv/mediawiki'
    }

    $ensure = mediawiki::state('primary_dc') ? {
        $::site => 'present',
        default => 'absent',
    }

    file { '/usr/local/bin/mw-cli-wrapper':
        source => 'puppet:///modules/profile/mediawiki/maintenance/mw-cli-wrapper.sh',
        owner  => 'root',
        group  => 'root',
        mode   => '0555'
    }

    # Mediawiki maintenance scripts (cron jobs)
    class { 'mediawiki::maintenance::pagetriage': ensure => $ensure }
    class { 'mediawiki::maintenance::translationnotifications': ensure => $ensure }
    class { 'mediawiki::maintenance::updatetranslationstats': ensure => $ensure }
    class { 'mediawiki::maintenance::wikidata': ensure => $ensure, ensure_testwiki => $ensure }
    class { 'mediawiki::maintenance::echo_mail_batch': ensure => $ensure }
    class { 'mediawiki::maintenance::parsercachepurging': ensure => $ensure }
    class { 'mediawiki::maintenance::cleanup_upload_stash': ensure => $ensure }
    class { 'mediawiki::maintenance::tor_exit_node': ensure => $ensure }
    class { 'mediawiki::maintenance::update_flaggedrev_stats': ensure => $ensure }
    class { 'mediawiki::maintenance::refreshlinks': ensure => $ensure }
    class { 'mediawiki::maintenance::update_special_pages': ensure => $ensure }
    class { 'mediawiki::maintenance::purge_abusefilter': ensure => $ensure }
    class { 'mediawiki::maintenance::purge_checkuser': ensure => $ensure }
    class { 'mediawiki::maintenance::purge_expired_userrights': ensure => $ensure }
    class { 'mediawiki::maintenance::purge_old_cx_drafts': ensure => $ensure }
    class { 'mediawiki::maintenance::purge_securepoll': ensure => $ensure }
    class { 'mediawiki::maintenance::jobqueue_stats': ensure => $ensure }
    class { 'mediawiki::maintenance::db_lag_stats': ensure => $ensure }
    class { 'mediawiki::maintenance::cirrussearch': ensure => $ensure }
    class { 'mediawiki::maintenance::generatecaptcha': ensure => $ensure }
    class { 'mediawiki::maintenance::pageassessments': ensure => $ensure }
    class { 'mediawiki::maintenance::uploads': ensure => $ensure }
    class { 'mediawiki::maintenance::readinglists': ensure => $ensure }
    class { 'mediawiki::maintenance::initsitestats': ensure => $ensure }

    # Include the cache warmup script; requires node and conftool
    require ::profile::conftool::client
    class { '::mediawiki::maintenance::cache_warmup':
        ensure => present,
    }

    # backup home directories to bacula, people work on these
    include ::profile::backup::host
    backup::set {'home': }

    # (T17434) Periodical run of currently disabled special pages
    class { 'mediawiki::maintenance::updatequerypages': ensure => $ensure }

    # Readline support for PHP maintenance scripts (T126262)
    require_package('php-readline')

    # GNU version of 'time' provides extra info like peak resident memory
    # anomie needs it, as opposed to the shell built-in time command
    require_package('time')

    # T112660 - kafka support
    # The eventlogging code is useful for scripting
    # EventLogging consumers.  Install this but don't
    # run any daemons.  To use eventlogging code,
    # add /srv/deployment/eventlogging/eventlogging
    # to your PYTHONPATH or sys.path.
    include ::eventlogging

    rsync::quickdatacopy { 'home-mwmaint':
        ensure      => present,
        auto_sync   => false,
        source_host => 'mwmaint2001.codfw.wmnet',
        dest_host   => 'mwmaint1002.eqiad.wmnet',
        module_path => '/home',
    }

    # T199124
    $motd_ensure = $ensure ? {
        'present' => 'absent',
        'absent'  => 'present',
        default   => 'present',
    }

    motd::script { 'inactive_warning':
        ensure   => $motd_ensure,
        priority => 1,
        content  => template('profile/mediawiki/maintenance/inactive.motd.erb'),
    }
}
