# manifests/gitblit.pp
# manifest to setup a gitblit instance

# Setup apache for the git viewer and replicated git repos
# Also needs gerrit::replicationdest installed
class gitblit::instance($host,
	$user = "gitblit",
	$git_repo_owner="gerritslave",
	$ssl_cert="",
	$ssl_cert_key="") {

	include webserver::apache

	generic::systemuser { $user: name => $user }

	file {
		"/etc/apache2/sites-available/git.wikimedia.org":
			mode => 0444,
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
		"/var/lib/${user}/data/gitblit.properties":
			mode => 0444,
			owner => $user,
			group => $user,
			source => "puppet:///files/gitblit/gitblit.properties",
			require => Systemuser[$user];
		"/var/lib/${user}/data/header.md":
			mode => 0444,
			owner => $user,
			group => $user,
			source => "puppet:///files/gitblit/header.md",
			require => Systemuser[$user];
		"/etc/init.d/gitblit":
			mode => 0554,
			owner => $user,
			group => $user,
			source => "puppet:///files/gitblit/gitblit-ubuntu",
			require => Systemuser[$user];
		"/var/www/robots.txt":
			mode => 0444,
			owner => root,
			group => root,
			content => "User-agent: *\nDisallow: /\n";
	}

	service {
		"gitblit":
			subscribe => File["/var/lib/${user}/data/gitblit.properties"],
			enable => true,
			ensure => running,
			require => Systemuser[$user];
	}

	apache_site { git: name => "git.wikimedia.org" }
	apache_module { headers: name => "headers" }
	apache_module { rewrite: name => "rewrite" }
	apache_module { proxy: name => "proxy" }
	apache_module { proxy_http: name => "proxy_http" }
	apache_module { ssl: name => "ssl" }
}
