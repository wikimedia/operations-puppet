class ganglia_new::monitor($cluster) {
	include packages, service

	class { "ganglia_new::monitor::config": cluster => $cluster }
}