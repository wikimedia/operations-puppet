# sudo.pp

define sudo_user( $user, $privileges ) {

	file { "/etc/sudoers.d/$user":
		owner => root,
		group => root,
		mode => 0440,
		content => template("sudo/sudoers.erb");
	}

}

define sudo_group( $group, $privileges ) {

	file { "/etc/sudoers.d/$group":
		owner => root,
		group => root,
		mode => 0440,
		content => template("sudo/sudoers.erb");
	}

}

class sudo::labs_project {

	# For all project except ones listed here, give sudo privileges
	# to all project members
	if ! ($instanceproject in ['testlabs', 'admininstances']) {
		# Paranoia check
		if $realm == "labs" {
			sudo_group { $instanceproject: group => "${instanceproject}", privileges => ['ALL = NOPASSWD: ALL'] }
		}
	}

}
