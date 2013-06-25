# manifests/role/gitblit.pp

class role::gitblit {
	system_role { "role::gitblit": description => "Gitblit, a git viewer" }

	include wmrole::gerrit::production::replicationdest

	class { "gitblit::instance":
		host => "git.wikimedia.org",
		ssl_cert => "git.wikimedia.org",
		ssl_cert_key => "git.wikimedia.org"
	}
}
