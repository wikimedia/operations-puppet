define ganglia::monitor::aggregator::instance() {
	Class[ganglia::monitor::aggregator] -> Ganglia::Monitor::Aggregator::Instance[$title]
	Ganglia::Monitor::Aggregator::Instance[$title] -> Service[ganglia-monitor-aggregator]

	$aggregator = true

	# TODO: support multiple $site
	$cluster = $title
	$id = $ganglia::configuration::clusters[$cluster]['id']
	$portnr = $ganglia::configuration::base_port + $id
	$gmond_port = $::realm ? {
		production => $portnr,
		labs => $::project_gid
	}
	$cname = "${cluster} ${::site}"

	file { "/etc/ganglia/aggregators/${id}.conf":
		mode => 0444,
		content => template("ganglia/gmond.conf.erb"),
		notify => Service[$title]
	}
}
