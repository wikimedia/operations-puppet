class ganglia::monitor($cluster) {
	include packages, service

	class { "ganglia::monitor::config": cluster => $cluster }
}