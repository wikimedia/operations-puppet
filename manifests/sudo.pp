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

define sudo_group($privileges ) {
	$group = $title

	file { "/etc/sudoers.d/$group":
		owner => root,
		group => root,
		mode => 0440,
		content => template("sudo/sudoers.erb");
	}

}

class sudo::labs_project {
	if $realm == labs {
		include sudo::default
	}

	# For all project except ones listed here, give sudo privileges
	# to all project members
	if ! ($instanceproject in ['testlabs', 'admininstances']) {
		# Paranoia check
		if $realm == "labs" {
			sudo_group { $instanceproject: privileges => ['ALL=(ALL) ALL'] }
		}
	}

}

class sudo::default {

	file { 
		"/etc/sudoers":
			owner => root,
			group => root,
			mode => 0440,
			source => "puppet:///files/sudo/sudoers.default";
		"/etc/sudoers.d":
			ensure => directory,
			owner => root,
			group => root,
			mode => 755;
	}

}
