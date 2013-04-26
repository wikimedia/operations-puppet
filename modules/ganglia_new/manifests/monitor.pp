class ganglia_new::monitor($cluster) {
	include packages, service
	include ganglia_new::configuration

	if $::realm == "production" {
		$id = $ganglia_new::configuration::clusters[$cluster]['id'] + $ganglia_new::configuration::id_prefix[$::site]
		$desc = $ganglia_new::configuration::clusters[$cluster]['name']
		$portnr = $ganglia_new::configuration::base_port + $id
	}
	$gmond_port = $::realm ? {
		production => $portnr,
		labs => $::project_gid
	}
	$cname = $::realm ? {
		production => "${desc} ${::site}",
		labs => $::instanceproject
	}
	$aggregator_hosts = $ganglia_new::configuration::aggregator_hosts[$::site]
	$override_hostname = $::realm ? {
		production => undef,
		labs => $::instancename
	}

	class { "ganglia_new::monitor::config":
		gmond_port => $gmond_port,
		cname => $cname,
		aggregator_hosts => $aggregator_hosts,
		override_hostname => $override_hostname
	}
}