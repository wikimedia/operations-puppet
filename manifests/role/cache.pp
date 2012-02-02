# role/cache.pp
# cache::squid and cache::varnish role classes

# Virtual resources for the monitoring server
@monitor_group { "cache_squid_text_pmtpa": description => "text squids pmtpa" }
@monitor_group { "cache_squid_text_eqiad": description => "text squids eqiad" }
@monitor_group { "cache_squid_text_esams": description => "text squids esams" }

@monitor_group { "cache_squid_upload_pmtpa": description => "upload squids pmtpa" }
@monitor_group { "cache_squid_upload_eqiad": description => "upload squids eqiad" }
@monitor_group { "cache_squid_upload_esams": description => "upload squids esams" }

class role::cache {
	class squid {
		class common($role) {
			system_role { "role::cache::squid::${role}": description => "${role} Squid server"}

			$cluster = "squids_${role}"
			$nagios_group = "cache_squid_${role}_${::site}"

			include lvs::configuration

			include	standard,
				squid
			
			class { "lvs::realserver": realserver_ips => $lvs::configuration::lvs_service_ips[$::realm][$role][$::site] }

			# Monitoring
			monitor_service {
				"frontend http":
					description => "Frontend Squid HTTP",
					check_command => $role ? {
						text => 'check_http',
						upload => 'check_http_upload',
					};
				"backend http":
					description => "Backend Squid HTTP",
					check_command => $role ? {
						text => 'check_http_on_port!3128',
						upload => 'check_http_upload_on_port!3128',
					};
			}

			# HTCP packet loss monitoring on the ganglia aggregators
			if $ganglia_aggregator == "true" and $::site != "esams" {
				include misc::monitoring::htcp-loss
			}
		}

		class text {
			class { "role::cache::squid::common": role => "text" }
		}

		class upload {
			class { "role::cache::squid::common": role => "upload" }
		}
	}
}
