# = Class: role::solr
#
# This class manages a Solr service in a WMF-specific way
#
# == Parameters:
#
# $schema::             Schema file for Solr (only one schema per instance supported)
# $replication_master:: Replication master, if this is current hostname, this server will be a master
# $monitor::            How to monitor this server:
#                       * "service" - just presence of Solr
#                       * "results" - whether Solr has some data in its index
#                       Any other input will disable monitoring
class role::solr($schema = undef, $replication_master = undef, $monitor = "service" ) {
	class { "::solr":
		schema => $schema,
		replication_master => $replication_master,
	}

	if ($monitor == "service") {
		monitor_service { "Solr":
			description => "Solr",
			check_command => "check_http_url_on_port!$::hostname!8983!/solr/select/?q=*%3A*&start=0&rows=1&indent=on"
		}
	}
	elsif ($monitor == "results") {
		monitor_service { "Solr":
			description => "Solr (with a result set check)",
			check_command => "check_http_url_for_string_on_port!$::hostname!8983!/solr/select/?q=*%3A*&start=0&rows=1&indent=on!'<str name=\"rows\">1</str>'"
		}
	}
}

class role::solr::ttm {
	system_role { "solr": description => "ttm solr backend" }

	class { "role::solr":
		schema => "puppet:///modules/solr/schema-ttmserver.xml"
	}
}

class role::solr::geodata {
	system_role { "solr-geodata": description => "Solr server for GeoData" }

	include standard

	class { "role::solr": schema => "puppet:///modules/solr/schema-geodata.xml" }
}

