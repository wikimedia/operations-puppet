# realm.pp
# Collection of global definitions used across sites, within one realm.
#

if $::realm == undef {
    $realm = 'production'
}

if $::instanceproject == undef {
    $instanceproject = ''
}

if $::projectgroup == undef {
    $projectgroup = "project-${instanceproject}"
}

# Determine the site the server is in
if $::ipaddress_eth0 != undef {
    $main_ipaddress = $ipaddress_eth0
} elsif $::ipaddress_bond0 != undef {
    $main_ipaddress = $ipaddress_bond0
} else {
    $main_ipaddress = $ipaddress
}

$site = $main_ipaddress ? {
    /^208\.80\.152\./                         => 'pmtpa',
    /^208\.80\.153\./                         => 'codfw',
    /^208\.80\.15[45]\./                      => 'eqiad',
    /^10\.[0-4]\./                            => 'pmtpa',
    /^10\.6[48]\./                            => 'eqiad',
    /^10\.192\./                              => 'codfw',
    /^91\.198\.174\./                         => 'esams',
    /^198\.35\.26\.([0-9]|[1-5][0-9]|6[0-2])/ => 'ulsfo',
    /^10\.128\./                              => 'ulsfo',
    /^10\.20\.0\./                            => 'esams',
    default                                   => '(undefined)'
}

$mw_primary = $::realm ? {
    'production' => 'eqiad',
    default => $::site
}

$network_zone = $main_ipaddress ? {
    /^10./  => 'internal',
    default => 'public'
}

# TODO: create hash of all LVS service IPs

# Set some basic variables
# TODO: update after codfw gets its nameservers
$nameservers = $site ? {
    'esams' => [ '91.198.174.6', '208.80.154.239' ],   # esams -> esams (nescio), eqiad (LVS)
    default => [ '208.80.154.239', '91.198.174.6' ],   # pmtpa+eqiad+ulsfo+codfw -> eqiad (LVS), esams (nescio)
}

# Allow per-server nameserver prefixes
$nameservers_prefix = []
$domain_search = $domain

# TODO: SMTP settings

# TODO: NTP settings

# TODO: Better nesting of settings inside classes

# Default group
$gid = 500

## puppet-accessible list of private wikis
## please keep alphabetized
$private_wikis = [ 
    'arbcom_dewiki',
    'arbcom_enwiki',
    'arbcom_fiwiki',
    'arbcom_nlwiki',
    'auditcomwiki',
    'boardgovcomwiki',
    'boardwiki',
    'chairwiki',
    'chapcomwiki',
    'checkuserwiki',
    'collabwiki',
    'execwiki',
    'fdcwiki',
    'grantswiki',
    'iegcomwiki',
    'ilwikimedia',
    'internalwiki',
    'legalteamwiki',
    'movementroleswiki',
    'noboard_chapterswikimedia',
    'officewiki',
    'ombudsmenwiki',
    'otrs_wikiwiki',
    'searchcomwiki',
    'spcomwiki',
    'stewardwiki',
    'transitionteamwiki',
    'wg_enwiki',
    'wikimaniateamwiki',
    'zerowiki' ]

$private_tables = [
    'accountaudit_login',
    'arbcom1_vote',
    'archive_old',
    'blob_orphans',
    'blob_tracking',
    'bv2009_edits',
    'categorylinks_old',
    'click_tracking',
    'cu_changes',
    'cu_log',
    'cur',
    'edit_page_tracking',
    'email_capture',
    'exarchive',
    'exrevision',
    'filejournal',
    'globalnames',
    'hidden',
    'image_old',
    'job',
    'linkscc',
    'localnames',
    'log_search',
    'logging_old',
    'long_run_profiling',
    'migrateuser_medium',
    'moodbar_feedback',
    'moodbar_feedback_response',
    'objectcache',
    'old_growth',
    'oldimage_old',
    'optin_survey',
    'pr_index',
    'prefstats',
    'prefswitch_survey',
    'profiling',
    'querycache',
    'querycache_info',
    'querycache_old',
    'querycachetwo',
    'securepoll_cookie_match',
    'securepoll_elections',
    'securepoll_entity',
    'securepoll_lists',
    'securepoll_msgs',
    'securepoll_options',
    'securepoll_properties',
    'securepoll_questions',
    'securepoll_strike',
    'securepoll_voters',
    'securepoll_votes',
    'spoofuser',
    'text',
    'titlekey',
    'transcache',
    'uploadstash',
    'user_newtalk',
    'vote_log',
    'watchlist' ]

# Route list for mail coming from MediaWiki mailer
$wikimail_smarthost = $::realm ? {
    'production' => [ 'wiki-mail-eqiad.wikimedia.org' ],
    # FIXME: find some SMTP servers for labs
    'labs'       => [ 'polonium.wikimedia.org', 'lead.wikimedia.org' ],
}
# Generic, default servers (order matters!)
$mail_smarthost = $::realm ? {
    'production' => [ 'polonium.wikimedia.org', 'lead.wikimedia.org' ],
    # FIXME: find some SMTP servers for labs
    'labs'       => [ 'polonium.wikimedia.org', 'lead.wikimedia.org' ],
}
