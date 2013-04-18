# manifests/role/gitblit.pp

class role::gitblit {
	system_role { "role::gitblit": description => "Gitblit, a git viewer" }

	include role::gerrit::production::replicationdest

	class { "gitblit":
		host => "git.wikimedia.org",
		ssl_cert => "star.wikimedia.org",
		ssl_cert_key => "star.wikimedia.org",
		ssl_ca => "Equifax_Secure_CA"
	}
}
