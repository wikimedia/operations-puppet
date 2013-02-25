# = Class: role::solr
#
# This class manages a Solr service in a WMF-specific way
#
# == Parameters:
#
# $schema::             Schema file for Solr (only one schema per instance supported)
# $replication_master:: Replication master, if this is current hostname, this server will be a master
class role::solr($schema = undef, $replication_master = undef ) {
	class { "::solr":
		schema => $schema,
		replication_master => $replication_master,
	}

	if ($replication_master) {
		$check_command = "check_replicated_solr"
	} else {
		$check_command = "check_solr"
	}
	monitor_service { "Solr":
		description => "Solr",
		check_command => "$check_command!400:600!5",
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

	class { "role::solr":
		schema => "puppet:///modules/solr/schema-geodata.xml",
		replication_master => 'solr1001.eqiad.wmnet',
	}
}

