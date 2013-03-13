class ganglia-new::monitor($cluster) {
	include packages, service

	class { "ganglia-new::monitor::config": cluster => $cluster }
}