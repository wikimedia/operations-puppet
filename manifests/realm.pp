# realm.pp
# Collection of global definitions used across sites, within one realm.
#

if $::realm == undef {
	$realm = "production"
}

if $::instanceproject == undef {
	$instanceproject = ''
}

if $::projectgroup == undef {
	$projectgroup = "project-$instanceproject"
}

# TODO: redo this in a much better way
$all_prefixes = [ "208.80.152.0/22", "91.198.174.0/24" ]

# Determine the site the server is in
if $::ipaddress_eth0 != undef {
	$main_ipaddress = $ipaddress_eth0
} elsif $::ipaddress_bond0 != undef {
	$main_ipaddress = $ipaddress_bond0
} else {
	$main_ipaddress = $ipaddress
}

$site = $main_ipaddress ? {
	/^208\.80\.15[23]\./	=> "pmtpa",
	/^208\.80\.15[45]\./	=> "eqiad",
	/^10\.[0-4]\./			=> "pmtpa",
	/^10\.6[48]\./				=> "eqiad",
	/^91\.198\.174\./		=> "esams",
	default					=> "(undefined)"
}

$mw_primary = $::realm ? {
	'production' => "eqiad",
	default => $::site
}

$network_zone = $main_ipaddress ? {
	/^10./			=> "internal",
	default			=> "public"
}

# TODO: create hash of all LVS service IPs

# Set some basic variables
$nameservers = $site ? {
	"esams"	=> [ "91.198.174.6", "208.80.152.131" ],
	"eqiad"	=> [ "208.80.154.239", "208.80.152.131" ],
	default	=> [ "208.80.152.131", "208.80.152.132" ]
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
$private_wikis = [ 'arbcom_dewiki',
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
		'wikimaniateamwiki', ]

$private_tables = [ 'accountaudit_login',
		'arbcom1_vote',
		'archive',
		'archive_old',
		'blob_orphans',
		'blob_tracking',
		'broken_cu_changes',
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
		'filearchive',
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
		'user_daily_contribs',
		'user_newtalk',
		'user_properties',
		'vote_log',
		'watchlist' ]

# Route list for mail coming from MediaWiki mailer
$exim_mediawiki_route_list = $::realm ? {
	'production' => 'smtp.pmtpa.wmnet',
	# FIXME: find some SMTP servers for labs
	'labs'       => 'mchenry.wikimedia.org:lists.wikimedia.org'
}
# Generic, default servers
$exim_default_route_list = $::realm ? {
	'production' => 'mchenry.wikimedia.org:lists.wikimedia.org',
	# FIXME: find some SMTP servers for labs
	'labs'       => 'mchenry.wikimedia.org:lists.wikimedia.org',
}
