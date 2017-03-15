# mediawiki maintenance scripts
class profile::mediawiki::maintenance::server {
    include scap::scripts
    include role::mediawiki::common

    include ::mediawiki::packages::php5

    file { $::mediawiki::scap::mediawiki_staging_dir:
        ensure => link,
        target => '/srv/mediawiki'
    }

    include mediawiki::maintenance::pagetriage
    include mediawiki::maintenance::translationnotifications
    include mediawiki::maintenance::updatetranslationstats
    include mediawiki::maintenance::wikidata
    include mediawiki::maintenance::echo_mail_batch
    include mediawiki::maintenance::parsercachepurging
    include mediawiki::maintenance::cleanup_upload_stash
    include mediawiki::maintenance::tor_exit_node
    include mediawiki::maintenance::update_flaggedrev_stats
    include mediawiki::maintenance::refreshlinks
    include mediawiki::maintenance::update_special_pages
    include mediawiki::maintenance::update_article_count
    include mediawiki::maintenance::purge_abusefilter
    include mediawiki::maintenance::purge_checkuser
    include mediawiki::maintenance::purge_securepoll
    include mediawiki::maintenance::jobqueue_stats
    include mediawiki::maintenance::cirrussearch
    include mediawiki::maintenance::generatecaptcha
    include mediawiki::maintenance::pageassessments
    include mediawiki::maintenance::uploads

    # Include the cache warmup script; requires node and conftool
    require ::profile::conftool::client
    class { '::mediawiki::maintenance::cache_warmup':
        ensure => present,
    }

    # backup home directories to bacula, people work on these
    include backup::host
    backup::set {'home': }

    # (T17434) Periodical run of currently disabled special pages
    include mediawiki::maintenance::updatequerypages

    # Readline support for PHP maintenance scripts (T126262)
    require_package('php5-readline')

    # T112660 - kafka support
    # The eventlogging code is useful for scripting
    # EventLogging consumers.  Install this but don't
    # run any daemons.  To use eventlogging code,
    # add /srv/deployment/eventlogging/eventlogging
    # to your PYTHONPATH or sys.path.
    include ::eventlogging

}
