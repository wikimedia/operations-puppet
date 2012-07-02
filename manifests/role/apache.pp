

class role::applicationserver {
	class common(
		$cluster,
# notes about $cluster and $nagios_group
# current clusters		: appserver, api_appserver, bits_appserver, imagescaler
# current nagios_ groups: appserver, api_appserver, bits_appserver, image_scalers <- this has gotta be renamed
		$nagios_group=$cluster,
		$apache=true,
		$lvsrealserver=true,
		$upload=true,
		$geoip=true,
		$jobrunner=false
		) {

		include	standard,
			admins::roots,
			admins::dctech,
			admins::mortals,
			accounts::l10nupdate

		if $lvsrealserver == true {
			include lvs::configuration
			class { "lvs::realserver": realserver_ips => [ $lvs::configuration::lvs_service_ips[$::realm][$cluster][$::site] ] }
		}

		if $apache == true {
			include	apaches::cron,
				apaches::service,
				apaches::pybal-check,
				apaches::monitoring,
				apaches::syslog
		}

		if $cluster == "imagesclager" {
			include	imagescaler::cron,
				imagescaler::packages,
				imagescaler::files
		}

		if $lvsrealserver == true {
			## need to replace this with swift stuff
			include	nfs::upload
		}

		if $geoip == true {
			include	geoip
		}
	
		if $jobrunner == true {
			include	jobrunner::packages
		}	
	}

	class appserver{
		class {"role::applicationserver::common": cluster => "appserver"}
	}

	class api_appserver{
		class {"role::applicationserver::common": cluster => "api_appserver"}
	}
	class bits_appserver{
		class {"role::applicationserver::common": cluster => "bits_appserver", upload => false}
	}
	class imagescaler{
		class {"role::applicationserver::common": cluster => "imagescaler", geoip => false, nagios_group => "image_scalers" } ##will change name of nagios group, but just recreating for now
	}
	class jobrunner{
		class {"role::applicationserver::common": cluster => "jobrunner", geoip => false, upload => false, lvsrealserver => false, apache => false }
	}
}

class role::applicationserver::labs {
	class common(
		$cluster,
		$geoip=true
		){

		include standard,
			mediawiki::packages,
			apaches::cron,
			apaches::service,
			apaches::monitoring::labs,
			nfs::apache::labs,
			nfs::upload

		if $cluster == "imagesclager" {
			include	imagescaler::cron,
				imagescaler::packages,
				imagescaler::files
		}

		if $geoip == true {
			include	generic::geoip::files
		}
	}

	class appserver{ 
		class {"role::applicationserver::labs::common": cluster => "appserver" }
	}
	class imagescaler{ 
		class {"role::applicationserver::labs::common": cluster => "imagescaler", geoip => false }
	}
}


