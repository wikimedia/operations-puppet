# logging (udp2log) servers

# base node definition from which logging nodes (emery, locke, oxygen, etc)
# inherit. Note that there is no real node named "base_analytics_logging_node".
# This is done as a base node primarily so that we can override the
# $nagios_contact_group variable.
node "base_analytics_logging_node" {
	system_role { "misc::log-collector": description => "log collector" }

	# include analytics in nagios_contact_group.
	# This is used by class base::monitoring::host for
	# notifications when a host or important service goes down.
	# NOTE:  This cannot be a fully qualified var
	# (i.e. $base::nagios_contact_group) because puppet does not
	# allow setting variables in other namespaces.  I could
	# parameterize class base AND class stanrdard and pass
	# the var down the chain, but that seems like too much
	# modification for just this.  Instead this overrides
	# the default contact_group of 'admins' set in class base.
	$nagios_contact_group = "admins,analytics"

	include
		standard,
		role::logging
}

class role::logging
{
	system_role { "misc::log-collector": description => "log collector" }

	# default gid
	$gid=500

	include
		groups::wikidev,
		admins::restricted,
		nrpe,
		geoip
}


