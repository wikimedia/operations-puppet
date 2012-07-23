# role/apaches.pp
# cache::applicationserver role class

# Virtual monitor group resources for the monitoring server
@monitor_group { "appserver": description => "pmtpa application servers" }
@monitor_group { "api_appserver": description => "pmtpa API application servers" }
@monitor_group { "bits_appserver": description => "pmtpa Bits application servers" }
@monitor_group { "imagescaler": description => "image scalers" }
@monitor_group { "jobrunner": description => "jobrunner application servers" }


# FIXME: add documentation for parameters
class role::applicationserver {
	class common(
		$cluster,
		$nagios_group=$cluster,
		$lvs_pool,
		$apache=true,
		$upload=true,
		$geoip=true,
		$jobrunner=false
		) {

# FIXME: is there any reason NOT to install geoip on a host?
# FIXME: what does $upload do?

		include	standard,
			mediawiki::packages

		if $::realm == 'production' {
			include	admins::roots,
				admins::dctech,
				admins::mortals,
				# FIXME: l10nupdate should move out of accounts::
				accounts::l10nupdate
				if $geoip == true {
					include	geoip
				}
		}

		# FIXME: $lvs_pool is always set. Do you mean to have a default value 'undef'?
		if $lvs_pool {
			include lvs::configuration
			class { "lvs::realserver": realserver_ips => [ $lvs::configuration::lvs_service_ips[$::realm][$lvs_pool][$::site] ] }
		}

		# FIXME: split this off to a separate (sub)class, remove parameter
		# In general it's not good style to put everything in one "common" class
		# just to enable/disable bits. In that case, it's not "common" :)
		if $apache == true {
			include	apaches::cron,
				apaches::service,
				apaches::pybal-check,
				apaches::syslog
			# FIXME: why pass a global variable as a parameter?
			# FIXME: move the monitoring stuff here
			class { "apaches::monitoring": realm => $realm }
		}

		# FIXME: cluster name has a typo
		# FIXME: move to a different (sub)class
		if $cluster == "imagesclager" {
			include	imagescaler::cron,
				imagescaler::packages,
				imagescaler::files
				if $::realm == 'labs' {
					include	nfs::apache::labs
				}
		}

		# FIXME: where does this variable come from? And what does it do?
		if $lvsrealserver == true {
			## need to replace this with swift stuff
			include	nfs::upload
		}

		# FIXME: move to different (sub)class
		if $jobrunner == true {
			include	jobrunner::packages
		}	
	}

	## prod role classes
	class appserver{
		class {"role::applicationserver::common": cluster => "appserver", lvs_pool => "apaches"}
	}
	class api_appserver{
		class {"role::applicationserver::common": cluster => "api_appserver", lvs_pool => "api"}
	}
	class bits_appserver{
		class {"role::applicationserver::common": cluster => "bits_appserver", lvs_pool => "apaches", upload => false}
	}
	class imagescaler{
		class {"role::applicationserver::common": cluster => "imagescaler", lvs_pool => "rendering", geoip => false }
	}
	class jobrunner{
		class {"role::applicationserver::common": cluster => "jobrunner", geoip => false, upload => false, lvsrealserver => false, apache => false }
	}
}

