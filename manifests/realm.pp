# realm.pp
# Collection of global definitions used across sites, within one realm.
#

<<<<<<< HEAD   (c10c64 Setting lvs addresses for labs)
if !$realm {
	$realm = "production"
}

# TODO: redo this in a much better way
$all_prefixes = [ "208.80.152.0/22", "91.198.174.0/24" ]

# Determine the site the server is in
$site = $ipaddress_eth0 ? {
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
=======
$realm = "production"

# TODO: redo this in a much better way
$all_prefixes = [ "208.80.152.0/22", "91.198.174.0/24" ]

# Determine the site the server is in
$site = $ipaddress_eth0 ? {
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

# FIXME: remove this, create special realm.pp for other realms
if !$cluster_env {
	$cluster_env = "production"
}
>>>>>>> BRANCH (3098d2 status based caching rule should be in frontend as well)
