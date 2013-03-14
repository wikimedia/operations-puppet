define ganglia_new::monitor::aggregator::instance() {
	include ganglia_new::configuration, network::constants

	$aggregator = true

	# TODO: support multiple $site
	$cluster = $title
	$id = $ganglia_new::configuration::clusters[$cluster]['id']
	$desc = $ganglia_new::configuration::clusters[$cluster]['name']
	$portnr = $ganglia_new::configuration::base_port + $id
	$gmond_port = $::realm ? {
		production => $portnr,
		labs => $::project_gid
	}
	$cname = "${desc} ${::site}"

	file { "/etc/ganglia/aggregators/${id}.conf":
		require => File["/etc/ganglia/aggregators"],
		mode => 0444,
		content => template("$module_name/gmond.conf.erb"),
		notify => Service["ganglia-monitor-aggregator-instance ID=${id}"]
	}

	service { "ganglia-monitor-aggregator-instance ID=${id}":
		require => File["/etc/ganglia/aggregators/${id}.conf"],
		provider => upstart,
		name => "ganglia-monitor-aggregator-instance",
		start => "/sbin/start ganglia-monitor-aggregator-instance ID=${id}",
		stop => "/sbin/stop ganglia-monitor-aggregator-instance ID=${id}",
		restart => "/sbin/restart ganglia-monitor-aggregator-instance ID=${id},"
		ensure => running
	}
}
