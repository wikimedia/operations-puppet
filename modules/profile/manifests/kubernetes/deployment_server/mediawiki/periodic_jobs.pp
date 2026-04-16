# SPDX-License-Identifier: Apache-2.0
class profile::kubernetes::deployment_server::mediawiki::periodic_jobs(
    Stdlib::Unixpath $helmfile_defaults_dir = lookup('profile::kubernetes::deployment_server::global_config::general_dir', {default_value => '/etc/helmfile-defaults'}),
) {
  concat { "${helmfile_defaults_dir}/mediawiki/periodic-jobs.yaml":
    ensure => present,
    tag    => 'kubernetes_mediawiki_periodic_jobs',
    owner  => 'mwdeploy',
    group  => 'deployment',
    mode   => '0644',
  }
  concat::fragment { 'periodic_jobs_header':
    target  => "${helmfile_defaults_dir}/mediawiki/periodic-jobs.yaml",
    content => "# SPDX-License-Identifier: Apache-2.0\nmwcron:\n  jobs:\n",
    order   => '01',
  }

  # MediaWiki maintenance scripts (periodic jobs).
  # This adds maintenance jobs to production. Remember to also add them to
  # modules/profile/manifests/mediawiki/maintenance.pp for beta.
  include ::profile::mediawiki::maintenance::serviceops_version
  include ::profile::mediawiki::maintenance::growthexperiments
  include ::profile::mediawiki::maintenance::startupregistrystats
  include ::profile::mediawiki::maintenance::wikidata
  include ::profile::mediawiki::maintenance::mediamoderation
  include ::profile::mediawiki::maintenance::globalblocking
  include ::profile::mediawiki::maintenance::pagetriage
  include ::profile::mediawiki::maintenance::translationnotifications
  include ::profile::mediawiki::maintenance::echo_mail_batch
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
  include ::profile::mediawiki::maintenance::readinglists
  include ::profile::mediawiki::maintenance::initsitestats
  include ::profile::mediawiki::maintenance::temporary_accounts
  include ::profile::mediawiki::maintenance::recount_categories
  include ::profile::mediawiki::maintenance::purge_expired_blocks
  include ::profile::mediawiki::maintenance::image_suggestions
  include ::profile::mediawiki::maintenance::campaignevents
  include ::profile::mediawiki::maintenance::purge_loginnotify
  include ::profile::mediawiki::maintenance::wikimediaevents
  include ::profile::mediawiki::maintenance::backfill_localaccounts
  include ::profile::mediawiki::maintenance::updatequerypages
  include ::profile::mediawiki::maintenance::email_verification_reminder
  include ::profile::mediawiki::maintenance::testkitchen
  include ::profile::mediawiki::maintenance::demote_ineligible_users
  include ::profile::mediawiki::maintenance::fundraising_data_import
  include ::profile::mediawiki::maintenance::abstractwiki_update_generated_articles
  include ::profile::mediawiki::maintenance::tk_constructive_edits
}
