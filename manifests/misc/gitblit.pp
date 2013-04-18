# manifests/gitblit.pp
# manifest to setup a gitblit instance

# Setup apache for the git viewer and replicated git repos
# Also needs gerrit::replicationdest installed
class gitblit($host,
	$user = "gitblit",
	$git_repo_owner="gerritslave",
	$ssl_cert="",
	$ssl_cert_key="",
	$ssl_ca="") {

	systemuser { $user: name => $user }

	file {
		"/etc/apache2/sites-available/git.wikimedia.org":
			mode => 0644,
			owner => root,
			group => root,
			content => template('apache/sites/git.wikimedia.org.erb'),
			ensure => present;
		"/var/lib/git":
			mode => 0644,
			owner => $git_repo_owner,
			group => $git_repo_owner,
			ensure => directory,
			require => User[$git_repo_owner];
	}

	apache_site { git: name => "git.wikimedia.org" }
	apache_module { rewrite: name => "rewrite" }
	apache_module { proxy: name => "proxy" }
	apache_module { proxy_http: name => "proxy_http" }
	apache_module { ssl: name => "ssl" }
}
