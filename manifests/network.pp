# network.pp

class network::constants {
	$external_networks = [ "91.198.174.0/24", "208.80.152.0/22", "2620:0:860::/46" ]
	$all_networks = [ "91.198.174.0/24", "208.80.152.0/22", "2620:0:860::/46", "10.0.0.0/8" ]
}

class network::checks {

	include passwords::network
	$snmp_ro_community = $passwords::network::snmp_ro_community

	# Nagios monitoring
	@monitor_group { "routers": description => "IP routers" }

	# Virtual resource for the monitoring host
	@monitor_host { "br1-knams": ip_address => "91.198.174.245", group => "routers" }
	@monitor_service { "br1-knams interfaces": host => "br1-knams", group => "routers", description => "Router interfaces", check_command => "check_ifstatus!${snmp_ro_community}" }

	@monitor_host { "csw1-esams": ip_address => "91.198.174.247", group => "routers" }
	@monitor_service { "csw1-esams bgp status": host => "csw1-esams", group => "routers", description => "BGP status", check_command => "check_bgpstate!${snmp_ro_community}" }

	@monitor_host { "csw2-esams": ip_address => "91.198.174.244", group => "routers" }
	@monitor_service { "csw2-esams bgp status": host => "csw2-esams", group => "routers", description => "BGP status", check_command => "check_bgpstate!${snmp_ro_community}" }

	@monitor_host { "cr1-eqiad": ip_address => "208.80.154.196", group => "routers" }
	@monitor_service { "cr1-eqiad interfaces": host => "cr1-eqiad", group => "routers", description => "Router interfaces", check_command => "check_ifstatus!${snmp_ro_community}" }
	@monitor_service { "cr1-eqiad bgp status": host => "cr1-eqiad", group => "routers", description => "BGP status", check_command => "check_bgpstate!${snmp_ro_community}" }

	@monitor_host { "cr2-eqiad": ip_address => "208.80.154.197", group => "routers" }
	@monitor_service { "cr2-eqiad interfaces": host => "cr2-eqiad", group => "routers", description => "Router interfaces", check_command => "check_ifstatus!${snmp_ro_community}" }
	@monitor_service { "cr2-eqiad bgp status": host => "cr2-eqiad", group => "routers", description => "BGP status", check_command => "check_bgpstate!${snmp_ro_community}" }

	@monitor_host { "cr1-sdtpa": ip_address => "208.80.152.196", group => "routers" }
	@monitor_service { "cr1-sdtpa interfaces": host => "cr1-sdtpa", group => "routers", description => "Router interfaces", check_command => "check_ifstatus!${snmp_ro_community}" }
	@monitor_service { "cr1-sdtpa bgp status": host => "cr1-sdtpa", group => "routers", description => "BGP status", check_command => "check_bgpstate!${snmp_ro_community}" }

	@monitor_host { "cr2-pmtpa": ip_address => "208.80.152.197", group => "routers" }
	@monitor_service { "cr2-pmtpa interfaces": host => "cr2-pmtpa", group => "routers", description => "Router interfaces", check_command => "check_ifstatus!${snmp_ro_community}" }
	@monitor_service { "cr2-pmtpa bgp status": host => "cr2-pmtpa", group => "routers", description => "BGP status", check_command => "check_bgpstate!${snmp_ro_community}" }

	@monitor_host { "mr1-pmtpa": ip_address => "10.1.2.3", group => "routers" }
	@monitor_service { "mr1-pmtpa interfaces": host => "mr1-pmtpa", group => "routers", description => "Router interfaces", check_command => "check_ifstatus!${snmp_ro_community}" }

	@monitor_host { "mr1-eqiad": ip_address => "10.65.0.1", group => "routers" }
	@monitor_service { "mr1-eqiad interfaces": host => "mr1-eqiad", group => "routers", description => "Router interfaces", check_command => "check_ifstatus!${snmp_ro_community}" }	
}

# This makes the monitoring host include the router group and
# perform the above checks

if $hostname in $nagios::configuration::master_hosts {
	include network::checks
}
