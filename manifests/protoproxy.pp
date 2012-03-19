define proxy_configuration( $proxy_addresses, $proxy_server_name, $proxy_server_cert_name, $proxy_backend, $enabled="false", $proxy_listen_flags='', $proxy_port='80', $ipv6_enabled='false' ) {

	nginx_site {
		"${name}":
			template => "proxy",
			install => "template",
			enable => $enable,
			require => Package["nginx"];
	}

}

class protoproxy::proxy_sites {

	if $enable_ipv6_proxy {
		$desc = "SSL and IPv6 proxy"
	} else {
		$desc = "SSL proxy"
	}
	system_role { "protoproxy::proxy_sites": description => $desc }

	$lvs_realserver_ips = $site ? {
		"pmtpa" => [ "208.80.152.200", "208.80.152.201", "208.80.152.202", "208.80.152.203", "208.80.152.204", "208.80.152.205", "208.80.152.206", "208.80.152.207", "208.80.152.208", "208.80.152.209", "208.80.152.210", "208.80.152.211", "208.80.152.3", "208.80.152.118" ],
		"eqiad" => [ "208.80.154.224", "208.80.154.225", "208.80.154.226", "208.80.154.227", "208.80.154.228", "208.80.154.229", "208.80.154.230", "208.80.154.231", "208.80.154.232", "208.80.154.233", "208.80.154.234", "208.80.154.235", "208.80.154.236" ],
		"esams" => [ "91.198.174.224", "91.198.174.225", "91.198.174.233", "91.198.174.234", "91.198.174.226", "91.198.174.227", "91.198.174.228", "91.198.174.229", "91.198.174.230", "91.198.174.231", "91.198.174.232", "91.198.174.235"  ]
	}

	require protoproxy::package

	include protoproxy::service,
		lvs::realserver

	# Tune kernel settings
	include generic::sysctl::high-http-performance

	$nginx_worker_connections = '32768'
	$nginx_use_ssl = true

	install_certificate{ "star.wikimedia.org": }
	install_certificate{ "star.wikipedia.org": }
	install_certificate{ "test-star.wikipedia.org": }
	install_certificate{ "star.wiktionary.org": }
	install_certificate{ "star.wikiquote.org": }
	install_certificate{ "star.wikibooks.org": }
	install_certificate{ "star.wikisource.org": }
	install_certificate{ "star.wikinews.org": }
	install_certificate{ "star.wikiversity.org": }
	install_certificate{ "star.mediawiki.org": }
	install_certificate{ "star.wikimediafoundation.org": }
	
	file {
		"/etc/nginx/nginx.conf":
			content => template('nginx/nginx.conf.erb'),
			notify => Service['nginx'],
			require => Package['nginx'];
	}

	file {
		"/etc/logrotate.d/nginx":
			content => template('nginx/logrotate'),
			require => Package['nginx'];
	}

	proxy_configuration{ wikimedia:
		proxy_addresses => {
			"pmtpa" => [ "208.80.152.200", "[2620:0:860:2::80:2]" ],
			"eqiad" => [ "208.80.154.224", "[2620:0:862:3::80:2]" ],
			"esams" => [ "91.198.174.224", "[2620:0:862:1::80:2]" ]
			},
		proxy_server_name => '*.wikimedia.org',
		proxy_server_cert_name => 'star.wikimedia.org',
		proxy_backend => {
			"pmtpa" => { "primary" => "10.2.1.25" },
			"eqiad" => { "primary" => "10.2.2.25" },
			"esams" => { "primary" => "10.2.3.25", "secondary" => "208.80.152.200" }
			},
		enabled => 'true',
		proxy_listen_flags => 'default ssl'
	}
	proxy_configuration{ bits:
		proxy_addresses => {
			"pmtpa" => [ "208.80.152.210", "[2620:0:860:2::80:2]" ],
			"eqiad" => [ "208.80.154.234", "[2620:0:862:3::80:2]" ],
			"esams" => [ "91.198.174.233", "[2620:0:862:1::80:2]" ]
			},
		proxy_server_name => 'bits.wikimedia.org geoiplookup.wikimedia.org',
		proxy_server_cert_name => 'star.wikimedia.org',
		proxy_backend => {
			"pmtpa" => { "primary" => "10.2.1.23" },
			"eqiad" => { "primary" => "10.2.2.23" },
			"esams" => { "primary" => "10.2.3.23", "secondary" => "208.80.152.210" }
			},
		enabled => 'true'
	}
	proxy_configuration{ upload:
		proxy_addresses => {
			"pmtpa" => [ "208.80.152.211", "[2620:0:860:2::80:2]" ],
			"eqiad" => [ "208.80.154.235", "[2620:0:862:3::80:2]" ],
			"esams" => [ "91.198.174.234", "[2620:0:862:1::80:2]" ]
			},
		proxy_server_name => 'upload.wikimedia.org',
		proxy_server_cert_name => 'star.wikimedia.org',
		proxy_backend => {
			"pmtpa" => { "primary" => "10.2.1.24" },
			"eqiad" => { "primary" => "10.2.2.24" },
			"esams" => { "primary" => "10.2.3.24", "secondary" => "208.80.152.211" }
			},
		ipv6_enabled => 'true',
		enabled => 'true'
	}
	proxy_configuration{ wikipedia:
		proxy_addresses => {
			"pmtpa" => [ "208.80.152.201", "[2620:0:860:2::80:2]" ],
			"eqiad" => [ "208.80.154.225", "[2620:0:862:3::80:2]" ],
			"esams" => [ "91.198.174.225", "[2620:0:862:1::80:2]" ]
			},
		proxy_server_name => '*.wikipedia.org',
		proxy_server_cert_name => 'test-star.wikipedia.org',
		proxy_backend => {
			"pmtpa" => { "primary" => "10.2.1.25" },
			"eqiad" => { "primary" => "10.2.2.25" },
			"esams" => { "primary" => "10.2.3.25", "secondary" => "208.80.152.201" }
			},
		enabled => 'true'
	}
	proxy_configuration{ wiktionary:
		proxy_addresses => {
			"pmtpa" => [ "208.80.152.202", "[2620:0:860:2::80:2]" ],
			"eqiad" => [ "208.80.154.226", "[2620:0:862:3::80:2]" ],
			"esams" => [ "91.198.174.226", "[2620:0:862:1::80:2]" ]
			},
		proxy_server_name => '*.wiktionary.org',
		proxy_server_cert_name => 'star.wiktionary.org',
		proxy_backend => {
			"pmtpa" => { "primary" => "10.2.1.25" },
			"eqiad" => { "primary" => "10.2.2.25" },
			"esams" => { "primary" => "10.2.3.25", "secondary" => "208.80.152.202" }
			},
		enabled => 'true'
	}
	proxy_configuration{ wikiquote:
		proxy_addresses => {
			"pmtpa" => [ "208.80.152.203", "[2620:0:860:2::80:2]" ],
			"eqiad" => [ "208.80.154.227", "[2620:0:862:3::80:2]" ],
			"esams" => [ "91.198.174.227", "[2620:0:862:1::80:2]" ]
			},
		proxy_server_name => '*.wikiquote.org',
		proxy_server_cert_name => 'star.wikiquote.org',
		proxy_backend => {
			"pmtpa" => { "primary" => "10.2.1.25" },
			"eqiad" => { "primary" => "10.2.2.25" },
			"esams" => { "primary" => "10.2.3.25", "secondary" => "208.80.152.203" }
			},
		enabled => 'true'
	}
	proxy_configuration{ wikibooks:
		proxy_addresses => {
			"pmtpa" => [ "208.80.152.204", "[2620:0:860:2::80:2]" ],
			"eqiad" => [ "208.80.154.228", "[2620:0:862:3::80:2]" ],
			"esams" => [ "91.198.174.228", "[2620:0:862:1::80:2]" ]
			},
		proxy_server_name => '*.wikibooks.org',
		proxy_server_cert_name => 'star.wikibooks.org',
		proxy_backend => {
			"pmtpa" => { "primary" => "10.2.1.25" },
			"eqiad" => { "primary" => "10.2.2.25" },
			"esams" => { "primary" => "10.2.3.25", "secondary" => "208.80.152.204" }
			},
		enabled => 'true'
	}
	proxy_configuration{ wikisource:
		proxy_addresses => {
			"pmtpa" => [ "208.80.152.205", "[2620:0:860:2::80:2]" ],
			"eqiad" => [ "208.80.154.229", "[2620:0:862:3::80:2]" ],
			"esams" => [ "91.198.174.229", "[2620:0:862:1::80:2]" ]
			},
		proxy_server_name => '*.wikisource.org',
		proxy_server_cert_name => 'star.wikisource.org',
		proxy_backend => {
			"pmtpa" => { "primary" => "10.2.1.25" },
			"eqiad" => { "primary" => "10.2.2.25" },
			"esams" => { "primary" => "10.2.3.25", "secondary" => "208.80.152.205" }
			},
		enabled => 'true'
	}
	proxy_configuration{ wikinews:
		proxy_addresses => {
			"pmtpa" => [ "208.80.152.206", "[2620:0:860:2::80:2]" ],
			"eqiad" => [ "208.80.154.230", "[2620:0:862:3::80:2]" ],
			"esams" => [ "91.198.174.230", "[2620:0:862:1::80:2]" ]
			},
		proxy_server_name => '*.wikinews.org',
		proxy_server_cert_name => 'star.wikinews.org',
		proxy_backend => {
			"pmtpa" => { "primary" => "10.2.1.25" },
			"eqiad" => { "primary" => "10.2.2.25" },
			"esams" => { "primary" => "10.2.3.25", "secondary" => "208.80.152.206" }
			},
		enabled => 'true'
	}
	proxy_configuration{ wikiversity:
		proxy_addresses => {
			"pmtpa" => [ "208.80.152.207", "[2620:0:860:2::80:2]" ],
			"eqiad" => [ "208.80.154.231", "[2620:0:862:3::80:2]" ],
			"esams" => [ "91.198.174.231", "[2620:0:862:1::80:2]" ]
			},
		proxy_server_name => '*.wikiversity.org',
		proxy_server_cert_name => 'star.wikiversity.org',
		proxy_backend => {
			"pmtpa" => { "primary" => "10.2.1.25" },
			"eqiad" => { "primary" => "10.2.2.25" },
			"esams" => { "primary" => "10.2.3.25", "secondary" => "208.80.152.207" }
			},
		enabled => 'true'
	}
	proxy_configuration{ mediawiki:
		proxy_addresses => {
			"pmtpa" => [ "208.80.152.208", "[2620:0:860:2::80:2]" ],
			"eqiad" => [ "208.80.154.232", "[2620:0:862:3::80:2]" ],
			"esams" => [ "91.198.174.232", "[2620:0:862:1::80:2]" ]
			},
		proxy_server_name => '*.mediawiki.org',
		proxy_server_cert_name => 'star.mediawiki.org',
		proxy_backend => {
			"pmtpa" => { "primary" => "10.2.1.25" },
			"eqiad" => { "primary" => "10.2.2.25" },
			"esams" => { "primary" => "10.2.3.25", "secondary" => "208.80.152.208" }
			},
		enabled => 'true'
	}
	proxy_configuration{ wikimediafoundation:
		proxy_addresses => {
			"pmtpa" => [ "208.80.152.209", "[2620:0:860:2::80:2]" ],
			"eqiad" => [ "208.80.154.233", "[2620:0:862:3::80:2]" ],
			"esams" => [ "91.198.174.235", "[2620:0:862:1::80:2]" ]
			},
		proxy_server_name => '*.wikimediafoundation.org',
		proxy_server_cert_name => 'star.wikimediafoundation.org',
		proxy_backend => {
			"pmtpa" => { "primary" => "10.2.1.25" },
			"eqiad" => { "primary" => "10.2.2.25" },
			"esams" => { "primary" => "10.2.3.25", "secondary" => "208.80.152.209" }
			},
		enabled => 'true'
	}
	proxy_configuration{ mobilewikipedia:
		proxy_addresses => {
			"pmtpa" => [ "127.0.0.1", "[2620:0:860:2::80:2]" ],
			"eqiad" => [ "208.80.154.236", "[2620:0:862:3::80:2]" ],
			"esams" => [ "127.0.0.1", "[2620:0:862:1::80:2]" ]
		},
		proxy_server_name => '*.m.wikipedia.org',
		proxy_server_cert_name => 'test-star.wikipedia.org',
		proxy_backend => {
			"pmtpa" => { "primary" => "10.2.1.26" },
			"eqiad" => { "primary" => "10.2.2.26" },
			"esams" => { "primary" => "10.2.3.26", "secondary" => "208.80.154.236" }
		},
		enabled => 'true'
	}
	# Misc services
	proxy_configuration{ videos:
		proxy_addresses => {
			"pmtpa" => [ "208.80.152.200", "[2620:0:860:2::80:2]" ],
			"eqiad" => [ "208.80.154.224", "[2620:0:862:3::80:2]" ],
			"esams" => [ "91.198.174.224", "[2620:0:862:1::80:2]" ] },
		proxy_server_name => 'videos.wikimedia.org',
		proxy_server_cert_name => 'star.wikimedia.org',
		proxy_backend => {
			"pmtpa" => { "primary" => "10.64.16.146" },
			"eqiad" => { "primary" => "10.64.16.146" },
			"esams" => { "primary" => "208.80.152.200", "secondary" => "208.80.152.200" }
			},
		enabled => 'true'
	}

}

class protoproxy::package {

	package { ['nginx']:
		ensure => latest;
	}

	file {
		"/etc/nginx/sites-enabled/default":
			ensure => absent;
	}

}

class protoproxy::service {
	require protoproxy::proxy_sites

	service { ['nginx']:
		enable => true,
		ensure => running;
	}
}

class protoproxy::ipv6_labs {

	include protoproxy::service

	nginx_site {
		"ipv6and4":
			template => "ipv6and4",
			install => "template",
			require => Package["nginx"];
	}

}

