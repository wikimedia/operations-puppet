# manifests/role/gitblit.pp

class role::gitblit {
	system::role { "role::gitblit": description => "Gitblit, a git viewer" }

	include role::gerrit::production::replicationdest

	class { "gitblit::instance":
		host => "git.wikimedia.org",
		ssl_cert => "git.wikimedia.org",
		ssl_cert_key => "git.wikimedia.org"
	}

	# Firewall GitBlit, it should be accessed from localhost or Varnish
	include base::firewall
	ferm::rule { 'gitblit_8080':
		rule => 'proto tcp dport 8080 { saddr $INTERNAL ACCEPT; DROP; }'
	}

	# NRPE for monitoring
	include nrpe
}
