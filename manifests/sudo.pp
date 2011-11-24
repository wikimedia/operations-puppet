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

<<<<<<< HEAD   (ddb719 dupload configuration)
define sudo_group( $group, $privileges ) {

	file { "/etc/sudoers.d/$group":
		owner => root,
		group => root,
		mode => 0440,
		content => template("sudo/sudoers.erb");
	}

}

class sudo::labs_project {

	include sudo::default

	# For all project except ones listed here, give sudo privileges
	# to all project members
	if ! ($instanceproject in ['testlabs', 'admininstances']) {
		# Paranoia check
		if $realm == "labs" {
			sudo_group { $instanceproject: group => "${instanceproject}", privileges => ['ALL=(ALL) ALL'] }
		}
	}

}

class sudo::default {

	file { "/etc/sudoers":
		owner => root,
		group => root,
		mode => 0440,
		source => "puppet:///files/sudo/sudoers.default";
=======
define sudo_group( $privileges ) {
	$group = $title

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
			sudo_group { "${instanceproject}": privileges => ['ALL = NOPASSWD: ALL'] }
		}
>>>>>>> BRANCH (341781 Move Package[git-core] into a generic-definitions class)
	}

}
