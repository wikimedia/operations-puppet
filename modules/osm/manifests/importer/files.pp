class osm::importer::files {
	file {
		"/var/lib/mod_tile/":
			ensure => directory, # so make this a directory
			owner => "osm",
			group => "osm",
			mode => 0644; # this mode will also apply to files from the source directory
		"/var/lib/mod_tile/.osmosis/":
			ensure => directory, # so make this a directory
			owner => "osm",
			group => "osm",
			mode => 0644, # this mode will also apply to files from the source directory
			require => Package["osmosis", "libapache2-mod-tile"];
		"/var/lib/mod_tile/.osmosis/configuration.txt":
			owner => osm,
			group => osm,
			mode => 0644,
			source => "puppet:///osm/osmosis.configuration.txt",
			require => Package["osmosis"];
		"/var/log/osm/":
			ensure => directory, # so make this a directory
			owner => "osm",
			group => "osm",
			mode => 0644, # this mode will also apply to files from the source directory
			require => User["osm"];
		"/usr/bin/openstreetmap-import-planet":
			mode => 0755,
			source => "puppet:///osm/import-planet",
			require => User["osm"];
		"/usr/bin/openstreetmap-update-db":
			mode => 0755,
			source => "puppet:///osm/load-next",
			require => User["osm"];
	}
}
