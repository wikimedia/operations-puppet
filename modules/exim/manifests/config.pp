class exim::config($install_type="light", $queuerunner="queueonly") {
	package { [ "exim4-config", "exim4-daemon-${install_type}" ]: ensure => latest }

	if $install_type == "heavy" {
		exec { "mkdir /var/spool/exim4/scan":
			require => Package[exim4-daemon-heavy],
			path => "/bin:/usr/bin",
			creates => "/var/spool/exim4/scan"
		}

		mount { [ "/var/spool/exim4/scan", "/var/spool/exim4/db" ]:
			device => "none",
			fstype => "tmpfs",
			options => "defaults",
			ensure => mounted
		}

		file { [ "/var/spool/exim4/scan", "/var/spool/exim4/db" ]:
			ensure => directory,
			owner => Debian-exim,
			group => Debian-exim
		}

		# add nagios to the Debian-exim group to allow check_disk tmpfs mounts (puppet still can't manage existing users?! so just Exec)
		exec { "nagios_to_exim_group":
			command => "usermod -a -G Debian-exim nagios",
			path => "/usr/sbin";
		}

		Exec["mkdir /var/spool/exim4/scan"] -> Mount["/var/spool/exim4/scan"] -> File["/var/spool/exim4/scan"]
		Package[exim4-daemon-heavy] -> Mount["/var/spool/exim4/db"] -> File["/var/spool/exim4/db"]
	}

	file {
		"/etc/default/exim4":
			require => Package[exim4-config],
			owner => root,
			group => root,
			mode => 0444,
			content => template("exim/exim4.default.erb");
		"/etc/exim4/aliases/":
			require => Package[exim4-config],
			mode => 0755,
			owner => root,
			group => root,
			ensure => directory;
	}
}
