# misc/monitoring.pp

class misc::monitoring::htcp-loss {
	system_role { "misc::monitoring::htcp-loss": description => "HTCP packet loss monitor" }

	File {
		require => File["/usr/lib/ganglia/python_modules"],
		notify => Service[gmond]
	}

	# Ganglia
	file {
		"/usr/lib/ganglia/python_modules/htcpseqcheck.py":
			source => "puppet:///files/ganglia/plugins/htcpseqcheck.py";
		"/usr/lib/ganglia/python_modules/htcpseqcheck_ganglia.py":
			source => "puppet:///files/ganglia/plugins/htcpseqcheck_ganglia.py";
		"/usr/lib/ganglia/python_modules/util.py":
			source => "puppet:///files/ganglia/plugins/util.py";
		"/usr/lib/ganglia/python_modules/compat.py":
			source => "puppet:///files/ganglia/plugins/compat.py";
		"/etc/ganglia/conf.d/htcpseqcheck.pyconf":
			# Disabled due to excessive memory and CPU usage -- TS
			notify => Service[gmond],
			ensure => absent;
			#require => File["/etc/ganglia/conf.d"],
			#source => "puppet:///files/ganglia/plugins/htcpseqcheck.pyconf";
	}
}

# == Class misc::monitoring::net::udp
# Sends UDP statistics to ganglia.
class misc::monitoring::net::udp {
	file {
		'/usr/lib/ganglia/python_modules/udp_stats.py':
			require => File['/usr/lib/ganglia/python_modules'],
			source => 'puppet:///files/ganglia/plugins/udp_stats.py',
			notify => Service[gmond];
		'/etc/ganglia/conf.d/udp_stats.pyconf':
			require => File["/usr/lib/ganglia/python_modules/udp_stats.py"],
			source => "puppet:///files/ganglia/plugins/udp_stats.pyconf",
			notify => Service[gmond];
	}
}