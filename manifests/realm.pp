# realm.pp
# Collection of global definitions used across sites, within one realm.
#

if !$realm {
	$realm = "production"
}

if !$instanceproject {
	$instanceproject = ''
}

if !$projectgroup {
	$projectgroup = "project-$instanceproject"
}

# TODO: redo this in a much better way
$all_prefixes = [ "208.80.152.0/22", "91.198.174.0/24" ]

# Determine the site the server is in
if $ipaddress_eth0 {
	$main_ipaddress = $ipaddress_eth0
} elsif $ipaddress_bond0 {
	$main_ipaddress = $ipaddress_bond0
} else {
	$main_ipaddress = $ipaddress
}

$site = $main_ipaddress ? {
	/^208\.80\.15[23]\./	=> "pmtpa",
	/^208\.80\.15[45]\./	=> "eqiad",
	/^10\.[0-4]\./			=> "pmtpa",
	/^10\.64\./				=> "eqiad",
	/^91\.198\.174\./		=> "esams",
	default					=> "(undefined)"
}

$network_zone = $ipaddress_eth0 ? {
	/^10./			=> "internal",
	default			=> "public"
}

# TODO: create hash of all LVS service IPs

# Set some basic variables
$nameservers = $site ? {
	"esams"	=> [ "91.198.174.6", "208.80.152.131" ],
	default	=> [ "208.80.152.131", "208.80.152.132" ]
}
$domain_search = $domain

# TODO: SMTP settings

# TODO: NTP settings

# TODO: Better nesting of settings inside classes

# Default group
$gid = 500

# remote syslog destination
# Default one is not really a remote but might avoid blackholing logs
$syslog_server = 'localhost'
case $::realm {

	'production': {
		if( $::site != '(undefined)' ) {
			$syslog_server = 'syslog.${::site}.wmnet'
		}
	}

	'labs': {
		# Per labs project syslog:
		case $::instanceproject {
			'deployment-prep': { $syslog_server = 'deployment-dbdump.pmtpa.wmflabs' }
		}
	}

} # end of $::syslog_server selection

