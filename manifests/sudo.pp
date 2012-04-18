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

	if $realm == labs {
		include sudo::default

		# Was handled via sudo ldap, now handled via puppet
		sudo_group { ops: privileges => ['ALL=(ALL) ALL'] }
		# Old way of handling this.
		sudo_group { $instanceproject: ensure => absent }
		# Another old way, before per-project sudo
		sudo_group { $projectgroup: ensure => absent }
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
