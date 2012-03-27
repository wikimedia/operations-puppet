class role::lucene {
	class indexer {
		system_role { "role::lucene::indexer": description => "Lucene search indexer" }
		$cluster = "search"
		$nagios_group = "lucene"

		include standard,
			admins::roots,
			admins::mortals,
			admins::restricted,
			lucene::users

		class { "lucene::server":
			indexer => "true", udplogging => "false"
		}
	}

	class front-end {
		class common($search_pool) {
			system_role { "role::lucene::front-end": description => "Front end lucene search server" }
			$cluster = "search"
			$nagios_group = "lucene"

			include lvs::configuration
			class { "lvs::realserver": realserver_ips => [ $lvs::configuration::lvs_service_ips[$::realm][$search_pool][$::site] ] }


			include standard,
				admins::roots,
				admins::mortals,
				admins::restricted,
				lucene::users

			class { "lucene::server":
				udplogging => "false"
			}
		}
		class pool1 {
			class { "role::lucene::front-end::common": search_pool => "search_pool1" } 
		}
		class pool2 {
			class { "role::lucene::front-end::common": search_pool => "search_pool2" } 
		}
		class pool3 {
			class { "role::lucene::front-end::common": search_pool => "search_pool3" } 
		}
		class pool4 {
			class { "role::lucene::front-end::common": search_pool => "search_pool4" } 
		}
		class prefix {
			class { "role::lucene::front-end::common": search_pool => "search_prefix" } 
		}
	}
}
