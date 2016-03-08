# mediawiki maintenance scripts
class role::mediawiki::maintenance {
    include scap::scripts
    include role::mediawiki::common

    file { $::mediawiki::scap::mediawiki_staging_dir:
        ensure => link,
        target => '/srv/mediawiki'
    }

    $job_default = $::site == $::mw_primary ? {
        true    => 'present',
        default => 'absent'
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

    # (T17434) Periodical run of currently disabled special pages
    include mediawiki::maintenance::updatequerypages

    # Readline support for PHP maintenance scripts (T126262)
    require_package('php5-readline')
}
