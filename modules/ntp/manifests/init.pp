# ntp.pp

class ntp {
	file { "ntp.conf":
		mode => 0644,
		owner => root,
		group => root,
		path => $operatingsystem ? {
			"Solaris" => "/etc/inet/ntp.conf",
			default   => "/etc/ntp.conf",
		},
		content => template("ntp/ntp-server.erb");
	}

	$packagename = $operatingsystem ? {
		Solaris => [ SUNWntpr, SUNWntpu ],
		default => ntp
	}

	package { $packagename:
		ensure => latest;
	}
	
	service { "ntp":
        	require => [ File["ntp.conf"], Package[$packagename] ],
		subscribe => File["ntp.conf"],
		ensure => running;
	}

	class client {
		$ntp_server = false

		if ! $ntp_servers {
			$ntp_servers = [ "linne.wikimedia.org", "dobson.wikimedia.org" ]
		}
		if ! $ntp_peers {
			$ntp_peers = []
		}

		include ntp

		# Monitoring
		monitor_service { "ntp": 
			description => "NTP", 
			check_command => "check_ntp_time!0.5!1",
			retries => 15, # wait for resync, don't flap after restart -- TS
		}
	}

	class server {
		$ntp_server = true

		system_role { "ntp::server": description => "NTP server" }

		if ! $ntp_servers {
			$ntp_servers = [ "198.186.191.229", "64.113.32.2", "173.8.198.242", "208.75.88.4", "75.144.70.35" ]
		}
		if ! $ntp_peers {
			$ntp_peers = []
		}

		include ntp

		# Monitoring
		monitor_service { "ntp peers":
			description => "NTP peers",
			check_command => "check_ntp_peer!0.1!0.5";
		}
	}

	class none {
		service { ntp:
			ensure => stopped;
		}
	}
}
