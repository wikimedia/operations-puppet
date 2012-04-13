# sudo.pp

define sudo_user( $privileges ) {
	$user = $title

	file { "/etc/sudoers.d/$user":
		owner => root,
		group => root,
		mode => 0440,
		content => template("sudo/sudoers.erb");
	}

}

define sudo_group($privileges=[], $ensure="present") {
	$group = $title

	file { "/etc/sudoers.d/$group":
		owner => root,
		group => root,
		mode => 0440,
		content => template("sudo/sudoers.erb"),
		ensure => $ensure;
	}

}

class sudo::labs_project {
	if $realm == labs {
		include sudo::default
	}

	# For all project except ones listed here, give sudo privileges
	# to all project members
	if ! ($projectgroup in ['testlabs', 'admininstances']) {
		# Paranoia check
		if $realm == "labs" {
			sudo_group { $projectgroup: privileges => ['ALL=(ALL) ALL'] }
			# Old way of handling this.
			sudo_group { $instanceproject: ensure => absent }
		}
	}

}

class sudo::default {

	file { "/etc/sudoers":
		owner => root,
		group => root,
		mode => 0440,
		source => "puppet:///files/sudo/sudoers.default";
	}

}
