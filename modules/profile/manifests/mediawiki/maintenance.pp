# mediawiki maintenance server
class profile::mediawiki::maintenance (
    Stdlib::Host $deployment_server = lookup('deployment_server'),
){
    # In order to be able to use the conftool-aware wrapper, we need to access
    # such data easily (on disk).
    require ::profile::conftool::state

    # httpd for noc.wikimedia.org
    class { '::httpd':
        modules => ['rewrite', 'headers'],
    }

    # firewall: allow http from deployment servers for testing with httpbb
    ferm::service { 'deploy-http-mwmaint':
        proto  => 'tcp',
        port   => 80,
        srange => "(@resolve((${deployment_server})) @resolve((${deployment_server}), AAAA))"
    }

    # Set the Server response header to the FQDN. (T255629)
    # Installing libapache2-mod-security2 without also installing modsecurity-crs
    # leads to a syntax error due to a bug in the former package which has
    # an include that is supposed to be optional but isn't optional. --dz 20200803
    package { [ 'libapache2-mod-security2', 'modsecurity-crs']:
        ensure => present
    }
    ::httpd::mod_conf { 'security2':
    }
    ::httpd::conf { 'server_header':
        content  => template('mediawiki/apache/server-header.conf.erb'),
    }

    # Deployment
    include ::scap::scripts

    file { $::mediawiki::scap::mediawiki_staging_dir:
        ensure => link,
        target => '/srv/mediawiki'
    }

    if $::realm != 'labs' {
        $ensure = mediawiki::state('primary_dc') ? {
            $::site => 'present',
            default => 'absent',
        }
    } else {
        $ensure = 'present'
    }

    file { '/usr/local/bin/mw-cli-wrapper':
        source => 'puppet:///modules/profile/mediawiki/maintenance/mw-cli-wrapper.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0555'
    }

    # MediaWiki maintenance scripts (periodic jobs)
    include ::profile::mediawiki::maintenance::wikidata
    include ::profile::mediawiki::maintenance::growthexperiments
    include ::profile::mediawiki::maintenance::mediamoderation
    include ::profile::mediawiki::maintenance::globalblocking
    include ::profile::mediawiki::maintenance::pagetriage
    include ::profile::mediawiki::maintenance::translationnotifications
    include ::profile::mediawiki::maintenance::updatetranslationstats
    include ::profile::mediawiki::maintenance::echo_mail_batch
    include ::profile::mediawiki::maintenance::parsercachepurging
    include ::profile::mediawiki::maintenance::cleanup_upload_stash
    include ::profile::mediawiki::maintenance::update_flaggedrev_stats
    include ::profile::mediawiki::maintenance::refreshlinks
    include ::profile::mediawiki::maintenance::update_special_pages
    include ::profile::mediawiki::maintenance::purge_abusefilter
    include ::profile::mediawiki::maintenance::purge_checkuser
    include ::profile::mediawiki::maintenance::purge_expired_userrights
    include ::profile::mediawiki::maintenance::purge_old_cx_drafts
    include ::profile::mediawiki::maintenance::purge_securepoll
    include ::profile::mediawiki::maintenance::db_lag_stats
    include ::profile::mediawiki::maintenance::cirrussearch
    include ::profile::mediawiki::maintenance::generatecaptcha
    include ::profile::mediawiki::maintenance::pageassessments
    class { 'mediawiki::maintenance::uploads': ensure => $ensure }
    include ::profile::mediawiki::maintenance::readinglists
    include ::profile::mediawiki::maintenance::initsitestats
    include ::profile::mediawiki::maintenance::startupregistrystats
    include ::profile::mediawiki::maintenance::temporary_accounts
    include ::profile::mediawiki::maintenance::recount_categories
    include ::profile::mediawiki::maintenance::purge_expired_blocks
    include ::profile::mediawiki::maintenance::image_suggestions
    include ::profile::mediawiki::maintenance::campaignevents
    include ::profile::mediawiki::maintenance::purge_loginnotify

    # Include the cache warmup script
    # TODO: T369921 - absent and remove.
    class { '::mediawiki::tools::cache_warmup':
        ensure => present,
    }

    # NOTE: T369921 - conftool was previously required by the cache warmup
    # script, but no longer is. It can be removed after verifying nothing else
    # on the maintenance hosts needs conftool.
    require ::profile::conftool::client

    # backup home directories to bacula, people work on these
    include ::profile::backup::host
    backup::set {'home': }

    # (T17434) Periodical run of currently disabled special pages
    include ::profile::mediawiki::maintenance::updatequerypages

    # Readline support for PHP maintenance scripts (T126262)
    ensure_packages('php-readline')

    # GNU version of 'time' provides extra info like peak resident memory
    # anomie needs it, as opposed to the shell built-in time command
    ensure_packages('time')

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
        source_host => 'mwmaint1002.eqiad.wmnet',
        dest_host   => 'mwmaint2002.codfw.wmnet',
        module_path => '/home',
    }

    if $::realm != 'labs' {
    # T199124
        $motd_ensure = $ensure ? {
            'present' => 'absent',
            'absent'  => 'present',
            default   => 'present',
        }
    } else {
        $motd_ensure = 'absent'
    }

    motd::script { 'inactive_warning':
        ensure   => $motd_ensure,
        priority => 1,
        content  => template('profile/mediawiki/maintenance/inactive.motd.erb'),
    }
}
