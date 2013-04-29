# gridengine/init.pp


class gridengine($gridmaster) {
	file { "/var/local/preseed":
		mode => 0600,
		ensure => directory,
	}

	file { "/var/local/preseed/gridengine.preseed":
		require => File["/var/local/preseed"],
		ensure => file,
		mode => 0600,
		backup => false,
		content => template("gridengine/gridengine.preseed.erb"),
	}

	package { "gridengine-common":
		require => File["/var/local/preseed/gridengine.preseed"],
		ensure => latest,
		responsefile => "/var/local/preseed/gridengine.preseed",
	}
}

