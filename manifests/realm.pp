# realm.pp
# Collection of global definitions used across sites, within one realm.
#

# Determine the site the server is in

# If our puppetmaster is 3.5+ then use the trusted $facts hash
if versioncmp($::serverversion, '3.5') >= 0 and $facts {
    if $facts['ipaddress_eth0'] {
        $main_ipaddress = $facts['ipaddress_eth0']
    } elsif $facts['ipaddress_bond0'] {
        $main_ipaddress = $facts['ipaddress_bond0']
    } else {
        $main_ipaddress = $facts['ipaddress']
    }
# Otherwise fallback to pre 3.5 behaviour
} else {
    if $::ipaddress_eth0 != undef {
        $main_ipaddress = $::ipaddress_eth0
    } elsif $::ipaddress_bond0 != undef {
        $main_ipaddress = $::ipaddress_bond0
    } else {
        $main_ipaddress = $::ipaddress
    }
}

$site = $main_ipaddress ? {
    /^208\.80\.15[23]\./                      => 'codfw',
    /^208\.80\.15[45]\./                      => 'eqiad',
    /^10\.6[48]\./                            => 'eqiad',
    /^10\.19[26]\./                           => 'codfw',
    /^91\.198\.174\./                         => 'esams',
    /^198\.35\.26\.([0-9]|[1-5][0-9]|6[0-2])/ => 'ulsfo',
    /^10\.128\./                              => 'ulsfo',
    /^10\.20\.0\./                            => 'esams',
    default                                   => '(undefined)'
}

if $realm == undef {
    $realm = hiera('realm', 'production')
}

if $realm == 'labs' {

    $labs_metal = hiera('labs_metal', {})
    if has_key($labs_metal, $::hostname) {
        $labsproject = $labs_metal[$::hostname]['project']
    } else {
        $labsproject = $::labsprojectfrommetadata
    }

    if $::labsproject == undef {
        fail('Failed to determine $::labsproject')
    }

    if $::projectgroup == undef {
        $projectgroup = "project-${labsproject}"
    }
}

# This is used to define the fallback site and is to be used by applications that
# are capable of automatically detecting a failed service and falling back to
# another one. Only the 2 sites that make sense to really be here are added for
# now
$other_site = $site ? {
    'codfw' => 'eqiad',
    'eqiad' => 'codfw',
    default => '(undefined)'
}

$app_routes = hiera('discovery::app_routes')

# Shortcut variables to use e.g. in hiera
$mw_primary = $app_routes['mediawiki']
$parsoid_site = $app_routes['parsoid']
$rb_site = $app_routes['restbase']
$mbapps_site = $app_routes['mobileapps']
$graphoid_site = $app_routes['graphoid']
$mathoid_site = $app_routes['mathoid']
$aqs_site = $app_routes['aqs']

$network_zone = $main_ipaddress ? {
    /^10./  => 'internal',
    default => 'public'
}

# TODO: create hash of all LVS service IPs

# Set some basic variables

# DNS
if $realm == 'labs' {
    $dnsconfig = hiera_hash('labsdnsconfig', {})
    $nameservers = [ ipresolve($dnsconfig['recursor'],4), ipresolve($dnsconfig['recursor_secondary'],4) ]
} else {
    $nameservers = $site ? {
        'eqiad' => [ '208.80.154.254', '208.80.153.254' ], # eqiad -> eqiad, codfw
        'codfw' => [ '208.80.153.254', '208.80.154.254' ], # codfw -> codfw, eqiad
        'ulsfo' => [ '208.80.154.254', '208.80.153.254' ], # ulsfo -> eqiad, codfw
        'esams' => [ '91.198.174.216', '208.80.154.254' ], # esams -> esams, eqiad
        default => [ '208.80.154.254', '208.80.153.254' ], #       -> eqiad, codfw
    }
}

# Temporary: puppetdb switch
# Note: $settings::storeconfigs_backend is a ruby symbol, thus it
# would never match in the equality below. So cast the variable to string. See
# https://tickets.puppetlabs.com/browse/PUP-6682
# lint:ignore:only_variable_string
$use_puppetdb = ("${settings::storeconfigs_backend}" == 'puppetdb')
# lint:endignore

# TODO: SMTP settings

# TODO: NTP settings

# TODO: Better nesting of settings inside classes

## puppet-accessible list of private wikis
## please keep alphabetized
$private_wikis = [
    'arbcom_cswiki',
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
    'ecwikimedia',
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
    'projectcomwiki',
    'searchcomwiki',
    'spcomwiki',
    'stewardwiki',
    'transitionteamwiki',
    'wg_enwiki',
    'wikimaniateamwiki',
    'zerowiki' ]

$private_tables = [
    '__wmf_checksum',
    'accountaudit_login',
    'arbcom1_vote',
    'archive_old',
    'blob_orphans',
    'blob_tracking',
    'bot_passwords',
    'bv2009_edits',
    'categorylinks_old',
    'click_tracking',
    'cu_changes',
    'cu_log',
    'cur',
    'echo_email_batch',
    'echo_event',
    'echo_target_page',
    'echo_unread_wikis',
    'echo_notification',
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
    'msg_resource',
    'oathauth_users',
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
$wikimail_smarthost = $realm ? {
    'production' => $site ? {
        'eqiad' => [ 'wiki-mail-eqiad.wikimedia.org', 'wiki-mail-codfw.wikimedia.org' ],
        'codfw' => [ 'wiki-mail-codfw.wikimedia.org', 'wiki-mail-eqiad.wikimedia.org' ],
        default => [ 'wiki-mail-eqiad.wikimedia.org', 'wiki-mail-codfw.wikimedia.org' ],
    },
    'labs'       => $::labsproject ? {
        'deployment-prep' => [ 'deployment-mx.eqiad.wmflabs' ],
        default           => [ 'mx1001.wikimedia.org', 'mx2001.wikimedia.org' ],
    },
}
# Generic, default servers (order matters!)
$mail_smarthost = $realm ? {
    'production' => $site ? {
        'eqiad' => [ 'mx1001.wikimedia.org', 'mx2001.wikimedia.org' ],
        'codfw' => [ 'mx2001.wikimedia.org', 'mx1001.wikimedia.org' ],
        default => [ 'mx1001.wikimedia.org', 'mx2001.wikimedia.org' ],
    },
    # FIXME: find some SMTP servers for labs
    'labs'       => [ 'mx1001.wikimedia.org', 'mx2001.wikimedia.org' ],
}
