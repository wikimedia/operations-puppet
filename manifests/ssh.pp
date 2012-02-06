# ssh.pp

class ssh {
	include ssh::client,
		ssh::hostkeys::publish,
		ssh::config,
		ssh::daemon

	class { "ssh::hostkeys::collect": }
}

class ssh::client {
	if $operatingsystem == "Ubuntu" {
		package { "openssh-client":
			ensure => latest
		}
	}
}

define sshhostkey($ip, $key) {
	$host = regsubst($title, '^([^\.]+)\..*$', '\1')

	sshkey {
		"$title":
			type => ssh-rsa,
			key => $key,
			ensure => present;
		"$host":
			type => ssh-rsa,
			key => $key,
			ensure => present;
		"$ip":
			type => ssh-rsa,
			key => $key,
			ensure => present;
	}
}


class ssh::hostkeys::publish {
	if $operatingsystem == "Ubuntu" {
		include ssh::client
	}

	# Store this hosts's host key
	case $sshrsakey {
		"": { 
			err("No sshrsakey on $fqdn")
		}
		default: {
			debug("Storing RSA ssh hostkey for $hostname.$domain")
			@@sshhostkey { $fqdn: ip => $ipaddress, key => $sshrsakey }
		}
	}
}

class ssh::hostkeys::collect {
	# Do this about twice a day
	if $hostname == "fenari" or $hostname == "bast1001" or generate("/usr/local/bin/position-of-the-moon") == "True" {
		notice("Collecting SSH host keys on $hostname.")

		# Install all collected ssh host keys
		Sshhostkey <<| |>>
	}
}

class ssh::config {
	if $operatingsystem == "Ubuntu" {
		file { "/etc/ssh/sshd_config":
			owner => root,
			group => root,
			mode  => 0444,
			content => template("ssh/sshd_config.erb");
		}
		if ( $realm == "labs" ) {
			file { "/etc/ssh/sshd_banner":
				owner => root,
				group => root,
				mode  => 0444,
				content => "If you are having access problems, please see: https://labsconsole.wikimedia.org/wiki/Access#Accessing_public_and_private_instances\n\n"
			}
		}
	}
}

class ssh::daemon {
	if $operatingsystem == "Ubuntu" {
		package { "openssh-server":
			ensure => latest;
		}
		
		service {
			ssh:
				ensure => running,
				subscribe => File["/etc/ssh/sshd_config"];
		}
	}
}
