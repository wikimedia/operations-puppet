# network.pp

class network::constants {
	$external_networks = [ "91.198.174.0/24", "208.80.152.0/22", "2620:0:860::/46" ]
	$all_networks = [ "91.198.174.0/24", "208.80.152.0/22", "2620:0:860::/46", "10.0.0.0/8" ]
	$all_network_subnets = {
		'production' => {
			'eqiad' => {
				'public' => {
					'public1-a-eqiad' => {
						'ipv4' => "208.80.154.0/26",
						'ipv6' => "2620:0:861:1::/64"
					},
					'public1-b-eqiad' => {
						'ipv4' => "208.80.154.128/26",
						'ipv6' => "2620:0:861:2::/64"
					},
					'public1-c-eqiad' => {
						'ipv4' => "208.80.154.64/26",
						'ipv6' => "2620:0:861:3::/64"
					},
				},
				'private' => {
					'private1-a-eqiad' => {
						'ipv4' => "10.64.0.0/22",
						'ipv6' => "2620:0:861:101::/64"
					},
					'private1-b-eqiad' => {
						'ipv4' => "10.64.16.0/22",
						'ipv6' => "2620:0:861:102::/64"
					},
					'private1-c-eqiad' => {
						'ipv4' => "10.64.32.0/22",
						'ipv6' => "2620:0:861:103::/64"
					},
					'labs-instances1-a-eqiad' => {
						'ipv4' => "10.68.0.0/24",
						'ipv6' => "2620:0:861:201::/64"
					},
					'labs-instances1-b-eqiad' => {
						'ipv4' => "10.68.16.0/24",
						'ipv6' => "2620:0:861:202::/64"
					},
					'labs-instances1-c-eqiad' => {
						'ipv4' => "10.68.32.0/24",
						'ipv6' => "2620:0:861:203::/64"
					},
					'labs-instances1-d-eqiad' => {
						'ipv4' => "10.68.48.0/24",
						'ipv6' => "2620:0:861:204::/64"
					},
					'labs-hosts1-a-eqiad' => {
						'ipv4' => "10.64.4.0/24",
						'ipv6' => "2620:0:861:117::/64"
					},
					'labs-hosts1-b-eqiad' => {
						'ipv4' => "10.64.20.0/24",
						'ipv6' => "2620:0:861:118::/64"
					},
					'labs-hosts1-c-eqiad' => {
						'ipv4' => "10.64.37.0/24",
						'ipv6' => "2620:0:861:119::/64"
					},
					'analytics1-b-eqiad' => {
						'ipv4' => "10.64.21.0/24",
						'ipv6' => "2620:0:861:105::/64"
					},
					'analytics1-c-eqiad' => {
						'ipv4' => "10.64.36.0/24",
						'ipv6' => "2620:0:861:106::/64"
					}
				},
			},
			'esams' => {
				'public' => {
					'public-services' => {
						'ipv4' => "91.198.174.0/25",
						'ipv6' => "2620:0:862:1::/64"
					},
					'backup-storage' => {
						'ipv4' => "91.198.174.128/26",
						'ipv6' => "2620:0:862:102::/64"
					},
				},
			},
			'pmtpa' => {
				'public' => {
					'public-services' => {
						'ipv4' => "208.80.152.128/26",
						'ipv6' => "2620:0:860:2::/64"
					},
					'public-services-2' => {
						'ipv4' => "208.80.153.192/26"
					},
					'sandbox' => {
						'ipv4' => "208.80.152.224/27",
						'ipv6' => "2620:0:860:3::/64"
					},
					'squid+lvs' => {
						'ipv4' => "208.80.152.0/25",
						'ipv6' => "2620:0:860:1::/64"
					},
				},
				'private' => {
					'virt-hosts' => {
						'ipv4' => "10.4.16.0/24"
					},
					'private' => {
						'ipv4' => "10.0.0.0/16"
					},
				},
			},
		},
	}
}

class network::checks {

	include passwords::network
	$snmp_ro_community = $passwords::network::snmp_ro_community

	# Nagios monitoring
	@monitor_group { "routers": description => "IP routers" }
	@monitor_group { "storage": description => "Storage equipment" }

	# Virtual resource for the monitoring host

	@monitor_host { "cr1-esams": ip_address => "91.198.174.245", group => "routers" }
	@monitor_service { "cr1-esams bgp status": host => "cr1-esams", group => "routers", description => "BGP status", check_command => "check_bgpstate!${snmp_ro_community}" }

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


	@monitor_host {
		"nas1-a.pmtpa.wmnet": ip_address => "10.0.0.253", group => "storage", critical => "true";
		"nas1-b.pmtpa.wmnet": ip_address => "10.0.0.254", group => "storage", critical => "true";
		"nas1001-a.eqiad.wmnet": ip_address => "10.64.16.4", group => "storage", critical => "true";
		"nas1001-b.eqiad.wmnet": ip_address => "10.64.16.5", group => "storage", critical => "true";
	}
}

# This makes the monitoring host include the router group and
# perform the above checks
include icinga::monitor::configuration::variables
if $hostname in $icinga::monitor::configuration::variables::master_hosts {
	include network::checks
}
