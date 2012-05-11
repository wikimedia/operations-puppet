# media-storage.pp

import "generic-definitions.pp"

class media-storage::thumbs-server {
	$nginx_worker_connections = 16384

	if ! $thumbs_proxy_source {
		$thumbs_proxy_source = "http://208.80.152.156"
	}

	if ! $thumbs_proxying {
		$thumbs_proxying = "false"
	}

	include generic::sysctl::high-http-performance

	system_role { "media-storage::thumbs-server": description => "Thumbnail server" }

	package { "nginx":
		ensure => "0.7.65-1ubuntu2.1";
	}

	file {
		"/etc/nginx/nginx.conf":
			require => Package[nginx],
			mode => 0444,
			content => template("nginx/nginx.conf.erb");
		"/etc/nginx/sites-enabled/default":
			ensure => absent;
	}

	nginx_site { "thumbs": install => "template" }

	service {
		nginx:
			require => [ Package[nginx], Nginx_site[thumbs], Service[noapache] ],
			subscribe => [ File["/etc/nginx/nginx.conf"], Nginx_site[thumbs] ],
			ensure => running;
		"noapache":
			name => apache,
			ensure => stopped; # Apache conflicts with nginx
	}

	# monitoring
	monitor_service { "nginx http":
		description => "nginx HTTP",
		check_command => "check_http_url!upload.wikimedia.org!/pybaltestfile.txt"
	}
}

class media-storage::thumbs-handler {
	system_role { "media-storage::thumbs-handler": description => "Thumbnail 404 handler" }

	package { [ "php5-cgi", "php5-curl", "spawn-fcgi" ]:
		ensure => latest;
	}

        upstart_job { "fcgi-thumb-handler": install => "true" }

	service { fcgi-thumb-handler:
		require => [ Package[php5-cgi], Package[php5-curl], Package[spawn-fcgi], Upstart_job["fcgi-thumb-handler"] ],
		subscribe => Upstart_job["fcgi-thumb-handler"],
                ensure => running;
	}
}

class media-storage::htcp-purger {
	system_role { "media-storage::htcp-purger": description => "HTCP thumbs purger" }

	upstart_job { "htcp-purger": install => "true" }

	service { "htcp-purger": ensure => running }

	file { "/etc/logrotate.d/htcp-purger":
		source => "puppet:///files/logrotate/htcp-purger";
	}
}
