# nagios.pp

import "generic-definitions.pp"
import "decommissioning.pp"

$nagios_config_dir = "/etc/nagios"

$ganglia_url = "http://ganglia.wikimedia.org"

define monitor_host ($ip_address=$ipaddress, $group=$nagios_group, $ensure=present, $critical="false", $contact_group="admins") {
	if ! $ip_address {
		fail("Parameter $ip_address not defined!")
	}

	# Export the nagios host instance
	@@nagios_host { $title:
		target => "${nagios_config_dir}/puppet_hosts.cfg",
		host_name => $title,
		address => $ip_address,
		hostgroups => $group ? {
			/.+/ => $group,
			default => undef
		},
		check_command => "check_ping!500,20%!2000,100%",
		check_period => "24x7",
		max_check_attempts => 2,
		contact_groups => $critical ? {
					"true" => "admins,sms",
					default => $contact_group
				},
		notification_interval => 0,
		notification_period => "24x7",
		notification_options => "d,u,r,f",
		ensure => $ensure;
	}

	if $title == $hostname {
		$image = $operatingsystem ? {
			"Ubuntu"	=> "ubuntu",
			"Solaris" 	=> "sunlogo",
			default		=> "linux40"
		}

		# Couple it with some hostextinfo
		@@nagios_hostextinfo { $title:
			target => "${nagios_config_dir}/puppet_hostextinfo.cfg",
			host_name => $title,
			notes => $title,
			# Needs c= cluster parameter. Let's fix this cleanly with Puppet 2.6 hashes
			notes_url => "${ganglia_url}/?c=${ganglia::cname}&h=${fqdn}&m=&r=hour&s=descending&hc=4",
			icon_image => "${image}.png",
			vrml_image => "${image}.png",
			statusmap_image => "${image}.gd2",
			ensure => $ensure;
		}
	}
}

define monitor_service ($description, $check_command, $host=$hostname, $retries=3, $group=$nagios_group, $ensure=present, $critical="false", $passive="false", $freshness=36000, $normal_check_interval=1, $retry_check_interval=1, $contact_group="admins") {
	if ! $host {
		fail("Parameter $host not defined!")
	}

	if $hostname in $decommissioned_servers {
		# Export the nagios service instance
		@@nagios_service { "$hostname $title":
			target => "${nagios_config_dir}/puppet_checks.d/${host}.cfg",
			host_name => $host,
			servicegroups => $group ? {
				/.+/ => $group,
				default => undef
			},
			service_description => $description,
			check_command => $check_command,
			max_check_attempts => $retries,
			normal_check_interval => $normal_check_interval,
			retry_check_interval => $retry_check_interval,
			check_period => "24x7",
	                notification_interval => 0,
			notification_period => "24x7",
			notification_options => "c,r,f",
			contact_groups => $critical ? {
						"true" => "admins,sms",
						default => $contact_group
					},
			ensure => absent;
		}
	}
	else {
		# Export the nagios service instance
		@@nagios_service { "$hostname $title":
			target => "${nagios_config_dir}/puppet_checks.d/${host}.cfg",
			host_name => $host,
			servicegroups => $group ? {
				/.+/ => $group,
				default => undef
			},
			service_description => $description,
			check_command => $check_command,
			max_check_attempts => $retries,
			normal_check_interval => $normal_check_interval,
			retry_check_interval => $retry_check_interval,
			check_period => "24x7",
			notification_interval => $critical ? {
					"true" => 240,
					default => 0
					},
			notification_period => "24x7",
			notification_options => "c,r,f",
			contact_groups => $critical ? {
						"true" => "admins,sms",
						default => $contact_group
					},
			passive_checks_enabled => 1,
			active_checks_enabled => $passive ? {
					"true" => 0,
					default => 1
					},
			is_volatile => $passive ? {
					"true" => 1,
					default => 0
					},
			check_freshness => $passive ? {
					"true" => 1,
					default => 0
					},
			freshness_threshold => $passive ? {
					"true" => $freshness,
					default => undef
					},
			ensure => $ensure;
		}
	}
}

define monitor_group ($description, $ensure=present) {
	# Nagios hostgroup instance
	nagios_hostgroup { $title:
		target => "${nagios_config_dir}/puppet_hostgroups.cfg",
		hostgroup_name => $title,
		alias => $description,
		ensure => $ensure;
	}

	# Nagios servicegroup instance
	nagios_servicegroup { $title:
		target => "${nagios_config_dir}/puppet_servicegroups.cfg",
		servicegroup_name => $title,
		alias => $description,
		ensure => $ensure;
	}
}

define decommission_monitor_host {
	if defined(Nagios_host[$title]) {
		# Override the existing resources
		Nagios_host <| title == $title |> {
			ensure => absent
		}
		Nagios_hostextinfo <| title == $title |> {
			ensure => absent
		}
	}
	else {
		# Resources don't exist in Puppet. Remove from Nagios config as well.
		nagios_host { $title:
			host_name => $title,
			ensure => absent;
		}

		nagios_hostextinfo { $title:
			host_name => $title,
			ensure => absent;
		}
	}
}


class nagios::gsbmonitoring {
	@monitor_host { "google": ip_address => "74.125.225.84" }

	@monitor_service { "GSB_mediawiki": description => "check google safe browsing for mediawiki.org", check_command => "check_http_url_for_string!www.google.com!/safebrowsing/diagnostic?site=mediawiki.org/!'This site is not currently listed as suspicious'", host => "google" }
	@monitor_service { "GSB_wikibooks": description => "check google safe browsing for wikibooks.org", check_command => "check_http_url_for_string!www.google.com!/safebrowsing/diagnostic?site=wikibooks.org/!'This site is not currently listed as suspicious'", host => "google" }
	@monitor_service { "GSB_wikimedia": description => "check google safe browsing for wikimedia.org", check_command => "check_http_url_for_string!www.google.com!/safebrowsing/diagnostic?site=wikimedia.org/!'This site is not currently listed as suspicious'", host => "google" }
	@monitor_service { "GSB_wikinews": description => "check google safe browsing for wikinews.org", check_command => "check_http_url_for_string!www.google.com!/safebrowsing/diagnostic?site=wikinews.org/!'This site is not currently listed as suspicious'", host => "google" }
	@monitor_service { "GSB_wikipedia": description => "check google safe browsing for wikipedia.org", check_command => "check_http_url_for_string!www.google.com!/safebrowsing/diagnostic?site=wikipedia.org/!'This site is not currently listed as suspicious'", host => "google" }
	@monitor_service { "GSB_wikiquotes": description => "check google safe browsing for wikiquotes.org", check_command => "check_http_url_for_string!www.google.com!/safebrowsing/diagnostic?site=wikiquotes.org/!'This site is not currently listed as suspicious'", host => "google" }
	@monitor_service { "GSB_wikisource": description => "check google safe browsing for wikisource.org", check_command => "check_http_url_for_string!www.google.com!/safebrowsing/diagnostic?site=wikisource.org/!'This site is not currently listed as suspicious'", host => "google" }
	@monitor_service { "GSB_wikiversity": description => "check google safe browsing for wikiversity.org", check_command => "check_http_url_for_string!www.google.com!/safebrowsing/diagnostic?site=wikiversity.org/!'This site is not currently listed as suspicious'", host => "google" }
	@monitor_service { "GSB_wiktionary": description => "check google safe browsing for wiktionary.org", check_command => "check_http_url_for_string!www.google.com!/safebrowsing/diagnostic?site=wiktionary.org/!'This site is not currently listed as suspicious'", host => "google" }
}


class misc::zfs::monitoring {
	monitor_service { "zfs raid": description => "ZFS RAID", check_command => "nrpe_check_zfs" }
}
