define ganglia_new::monitor::aggregator::instance($site) {
	Ganglia_new::Monitor::Aggregator::Instance[$title] -> Service[ganglia-monitor-aggregator]

	include ganglia_new::configuration, network::constants

	$aggregator = true

	if has_key($ganglia_new::configuration::clusters[$cluster], 'sites') {
		$sites = $ganglia_new::configuration::clusters[$cluster]['sites']
	} else {
		$sites = $ganglia_new::configuration::default_sites
	}
	$cluster = $title
	$id = $ganglia_new::configuration::clusters[$cluster]['id']
	$desc = $ganglia_new::configuration::clusters[$cluster]['name']
	$portnr = $ganglia_new::configuration::base_port + $ganglia_new::configuration::site_port_prefix[$site] + $id
	$gmond_port = $::realm ? {
		production => $portnr,
		labs => $::project_gid
	}
	$cname = "${desc} ${::site}"
	$ensure = $site in $sites ? {
		true => present,
		default => absent
	}

	file { "/etc/ganglia/aggregators/${id}.conf":
		require => File["/etc/ganglia/aggregators"],
		mode => 0444,
		content => template("$module_name/gmond.conf.erb"),
		notify => Service["ganglia-monitor-aggregator"],
		ensure => $ensure
	}
}
