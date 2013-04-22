# = Class: role::solr
#
# This class manages a Solr service in a WMF-specific way
#
# == Parameters:
#
# $schema::               Schema file for Solr (only one schema per instance supported)
# $replication_master::   Replication master, if this is current hostname, this server will be a master
# $average_request_time:: Average request time check threshold, the format is
#                         "warning threshold:error threshold", or simply "error threshold"
class role::solr($schema = undef, $replication_master = undef, $average_request_time = "400:600" ) {
	class { "::solr":
		schema => $schema,
		replication_master => $replication_master,
	}

	$check_command = $replication_master ? {
		undef => "check_solr",
		default => "check_replicated_solr"
	}
	monitor_service { "Solr":
		description => "Solr",
		check_command => "$check_command!$average_request_time!5",
	}
}

class role::solr::ttm {
	system_role { "solr": description => "ttm solr backend" }

	class { "role::solr":
		schema => "puppet:///modules/solr/schema-ttmserver.xml",
		average_request_time => '1000:1500', # Translate uses fairly slow queries
	}
}

class role::solr::geodata($replication_master = 'solr1001.eqiad.wmnet') {
	system_role { "solr-geodata": description => "Solr server for GeoData" }

	include standard

	class { "role::solr":
		schema => "puppet:///modules/solr/schema-geodata.xml",
		replication_master => $replication_master,
	}
}

class role::solr::geodata::labs {
	class { "role::solr::geodata":
		replication_master => undef,
	}
}