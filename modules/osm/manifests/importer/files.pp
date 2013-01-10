class osm::importer::files {
	file { "/var/lib/mod_tile/.osmosis/":
		ensure => directory, # so make this a directory
		recurse => true, # enable recursive directory management
		owner => "osm",
		group => "osm",
		mode => 0644, # this mode will also apply to files from the source directory
		require => Package["osmosis"],
	}

	file {
		"/var/lib/mod_tile/.osmosis/configuration.txt":
			owner => osm,
			group => osm,
			mode => 0644,
			source => "puppet:///files/osm/osmosis.configuration.txt",
			require => Package["osmosis"],
	}

	file { "/var/log/osm/":
		ensure => directory, # so make this a directory
		recurse => true, # enable recursive directory management
		owner => "osm",
		group => "osm",
		mode => 0644, # this mode will also apply to files from the source directory
		require => User["osm"],
	}

	file { "/usr/bin/openstreetmap-import-planet":
		mode => 0755,
		source => "puppet:///files/osm/import-planet",
		require => User["osm"],
	
	}

	file { "/usr/bin/openstreetmap-update-db":
		mode => 0755,
		source => "puppet:///files/osm/load-next",
		require => User["osm"],
	}
}
