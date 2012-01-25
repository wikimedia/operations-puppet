class nrpe::packages {
	package { [ "opsview-agent" ]:
		ensure => absent;
	}
        package { "nagios-nrpe-server":
                ensure => latest;
        }

	include nagios::packages::plugins

	$nrpe_allowed_hosts = $realm ? {
		"production" => "127.0.0.1,208.80.152.185,208.80.152.161",
		"labs" => "10.4.0.34"
	}

        file {
                "/etc/nagios/nrpe_local.cfg":
                        owner => root,
                        group => root,
                        mode => 0644,
                        content => template("nagios/nrpe_local.cfg.erb");
		"/usr/lib/nagios/plugins/check_ram.sh":
			owner => root,
			group => root,
			mode => 0755,
			source => "puppet:///files/nagios/check_ram.sh";
		"/usr/lib/nagios/plugins/check_dpkg":
			owner => root,
			group => root,
			mode => 0755,
			source => "puppet:///files/nagios/check_dpkg";
        }
}

class nrpe::service {
	service { nagios-nrpe-server:
		require => [ Package[nagios-nrpe-server], File["/etc/nagios/nrpe_local.cfg"], File["/usr/lib/nagios/plugins/check_dpkg"] ],
		subscribe => File["/etc/nagios/nrpe_local.cfg"],
		pattern => "/usr/sbin/nrpe",
		ensure => running;
	}

	if $lsbdistid == "Ubuntu" and versioncmp($lsbdistrelease, "10.04") >= 0 {
		file { "/etc/sudoers.d/nrpe":
			owner => root,
			group => root,
			mode => 0440,
			content => "
nagios	ALL = (root) NOPASSWD: /usr/bin/arcconf getconfig 1
nagios	ALL = (root) NOPASSWD: /usr/bin/check-raid.py
";
		}
	}
}

class nrpe {
	include nrpe::packages
	include nrpe::service

	# Collect virtual NRPE nagios service checks
	Monitor_service <| tag == "nrpe" |>
}
