# == Definition: proxy_configuration
#
# This class creates a nginx site. The parameters are merely expanded in the
# templates which has all of the logic.
#
# The resulting site will always listen on the server real IP.
#
# === Parameters:
#
# [*proxy_addresses*]
# Additional IP address to listen to. IPv6 addresses will be skipped
# unless *IpV6_enabled* is true.  The hash first level is made of sites
# entries, the IP are passed as an array.
#
# [*proxy_server_name*]
#
# [*proxy_server_cert_name*]
#
# [*proxy_backend*]
#
# [*enabled*]
# Whether to enable the site configuration. It will always be generated under
# /etc/nginx/sites-available , enabling this parameter will create a symbolic
# link under /etc/nginx/sites-enabled.
# Defaults to false
#
# [*proxy_listen_flags*]
# Defaults to ''
#
# [*proxy_port*]
# The TCP port to listen on.
# Defaults to '80'
#
# [*ipV6_enabled*]
# Whether to have the site listen on IPv6 addresses set via *proxy_addresses*
# Defaults to false
#
# [*ssl_backend*]
# Defaults to {}
#
define proxy_configuration(
  $proxy_addresses,
  $proxy_server_name,
  $proxy_server_cert_name,
  $proxy_backend,
  $enabled=false,
  $proxy_listen_flags='',
  $proxy_port='80',
  $ipv6_enabled=false,
  $ssl_backend={},
) {

  nginx_site { $name:
    template => 'proxy',
    install  => 'template',
    enable   => $enabled,
    require  => Package['nginx'],
  }

}

class protoproxy::proxy_sites {

  if $enable_ipv6_proxy {
    $desc = 'SSL and IPv6 proxy'
  } else {
    $desc = 'SSL proxy'
  }
  system_role { 'protoproxy::proxy_sites': description => $desc }

  # FIXME: pull from lvs::configuration
  class { 'lvs::realserver':
    realserver_ips => $::site ? {
      'pmtpa' => [ '208.80.152.200', '208.80.152.201', '208.80.152.202', '208.80.152.203', '208.80.152.204', '208.80.152.205', '208.80.152.206', '208.80.152.207', '208.80.152.208', '208.80.152.209', '208.80.152.210', '208.80.152.211', '208.80.152.3', '208.80.152.118', '208.80.152.218', '208.80.152.219', '2620:0:860:ed1a::', '2620:0:860:ed1a::1', '2620:0:860:ed1a::2', '2620:0:860:ed1a::3', '2620:0:860:ed1a::4', '2620:0:860:ed1a::5', '2620:0:860:ed1a::6', '2620:0:860:ed1a::7', '2620:0:860:ed1a::8', '2620:0:860:ed1a::9', '2620:0:860:ed1a::a', '2620:0:860:ed1a::b', '2620:0:860:ed1a::c', '2620:0:860:ed1a::12', '2620:0:860:ed1a::13' ],
      'eqiad' => [ '208.80.154.224', '208.80.154.225', '208.80.154.226', '208.80.154.227', '208.80.154.228', '208.80.154.229', '208.80.154.230', '208.80.154.231', '208.80.154.232', '208.80.154.233', '208.80.154.234', '208.80.154.235', '208.80.154.236', '208.80.154.242', '208.80.154.243', '2620:0:861:ed1a::', '2620:0:861:ed1a::1', '2620:0:861:ed1a::2', '2620:0:861:ed1a::3', '2620:0:861:ed1a::4', '2620:0:861:ed1a::5', '2620:0:861:ed1a::6', '2620:0:861:ed1a::7', '2620:0:861:ed1a::8', '2620:0:861:ed1a::9', '2620:0:861:ed1a::a', '2620:0:861:ed1a::b', '2620:0:861:ed1a::c', '2620:0:861:ed1a::12', '2620:0:861:ed1a::13' ],
      'esams' => [ '91.198.174.224', '91.198.174.225', '91.198.174.233', '91.198.174.234', '91.198.174.226', '91.198.174.227', '91.198.174.228', '91.198.174.229', '91.198.174.230', '91.198.174.231', '91.198.174.232', '91.198.174.235', '2620:0:862:ed1a::', '2620:0:862:ed1a::1', '2620:0:862:ed1a::2', '2620:0:862:ed1a::3', '2620:0:862:ed1a::4', '2620:0:862:ed1a::5', '2620:0:862:ed1a::6', '2620:0:862:ed1a::7', '2620:0:862:ed1a::8', '2620:0:862:ed1a::9', '2620:0:862:ed1a::a', '2620:0:862:ed1a::b', '2620:0:862:ed1a::c' ],
    }
  }

  require protoproxy::package
  include protoproxy::service
  include protoproxy::ganglia

  # Tune kernel settings
  include generic::sysctl::high-http-performance

  $nginx_worker_connections = '32768'
  $nginx_use_ssl = true

  install_certificate{ 'star.wikimedia.org': }
  install_certificate{ 'star.wikipedia.org': }
  install_certificate{ 'star.wiktionary.org': }
  install_certificate{ 'star.wikiquote.org': }
  install_certificate{ 'star.wikibooks.org': }
  install_certificate{ 'star.wikisource.org': }
  install_certificate{ 'star.wikinews.org': }
  install_certificate{ 'star.wikiversity.org': }
  install_certificate{ 'star.mediawiki.org': }
  install_certificate{ 'star.wikimediafoundation.org': }
  install_certificate{ 'star.wikidata.org': }
  install_certificate{ 'star.wikivoyage.org': }
  install_certificate{ 'unified.wikimedia.org': }

  file { '/etc/nginx/nginx.conf':
    content => template('nginx/nginx.conf.erb'),
    notify  => Service['nginx'],
    require => Package['nginx'],
  }

  file { '/etc/logrotate.d/nginx':
    content => template('nginx/logrotate'),
    require => Package['nginx'],
  }

  nginx_site { 'localhost.conf':
    install => true,
    enable  => true,
    require => Package['nginx'],
  }

  proxy_configuration{ 'wikimedia':
    proxy_addresses   => {
      'pmtpa' => [ '208.80.152.200', '[2620:0:860:ed1a::]' ],
      'eqiad' => [ '208.80.154.224', '[2620:0:861:ed1a::]' ],
      'esams' => [ '91.198.174.224', '[2620:0:862:ed1a::]' ],
      },
    proxy_server_name => '*.wikimedia.org',
    proxy_server_cert_name => 'unified.wikimedia.org',
    proxy_backend     => {
      'pmtpa' => { 'primary' => '10.2.1.25' },
      'eqiad' => { 'primary' => '10.2.2.25' },
      'esams' => { 'primary' => '10.2.3.25', 'secondary' => '208.80.152.200' },
      },
    ipv6_enabled       => true,
    enabled => true,
    proxy_listen_flags => 'default ssl',
  }
  proxy_configuration{ 'bits':
    proxy_addresses => {
      'pmtpa' => [ '208.80.152.210', '[2620:0:860:ed1a::a]' ],
      'eqiad' => [ '208.80.154.234', '[2620:0:861:ed1a::a]' ],
      'esams' => [ '91.198.174.233', '[2620:0:862:ed1a::a]' ],
      },
    proxy_server_name => 'bits.wikimedia.org geoiplookup.wikimedia.org',
    proxy_server_cert_name => 'unified.wikimedia.org',
    proxy_backend => {
      'pmtpa' => { 'primary' => '10.2.1.23' },
      'eqiad' => { 'primary' => '10.2.2.23' },
      'esams' => { 'primary' => '10.2.3.23', 'secondary' => '208.80.152.210' },
      },
    ipv6_enabled => true,
    enabled => true,
  }
  proxy_configuration{ 'upload':
    proxy_addresses => {
      'pmtpa' => [ '208.80.152.211', '[2620:0:860:ed1a::b]' ],
      'eqiad' => [ '208.80.154.235', '[2620:0:861:ed1a::b]' ],
      'esams' => [ '91.198.174.234', '[2620:0:862:ed1a::b]' ],
      },
    proxy_server_name => 'upload.wikimedia.org',
    proxy_server_cert_name => 'unified.wikimedia.org',
    proxy_backend => {
      'pmtpa' => { 'primary' => '10.2.1.24' },
      'eqiad' => { 'primary' => '10.2.2.24' },
      'esams' => { 'primary' => '10.2.3.24', 'secondary' => '208.80.152.211' },
      },
    ipv6_enabled => true,
    enabled => true,
  }
  proxy_configuration{ 'wikipedia':
    proxy_addresses => {
      'pmtpa' => [ '208.80.152.201', '[2620:0:860:ed1a::1]' ],
      'eqiad' => [ '208.80.154.225', '[2620:0:861:ed1a::1]' ],
      'esams' => [ '91.198.174.225', '[2620:0:862:ed1a::1]' ],
      },
    proxy_server_name => '*.wikipedia.org',
    proxy_server_cert_name => 'unified.wikimedia.org',
    proxy_backend => {
      'pmtpa' => { 'primary' => '10.2.1.25' },
      'eqiad' => { 'primary' => '10.2.2.25' },
      'esams' => { 'primary' => '10.2.3.25', 'secondary' => '208.80.152.201' },
      },
    ipv6_enabled => true,
    enabled => true,
  }
  proxy_configuration{ 'wiktionary':
    proxy_addresses => {
      'pmtpa' => [ '208.80.152.202', '[2620:0:860:ed1a::2]' ],
      'eqiad' => [ '208.80.154.226', '[2620:0:861:ed1a::2]' ],
      'esams' => [ '91.198.174.226', '[2620:0:862:ed1a::2]' ],
      },
    proxy_server_name => '*.wiktionary.org',
    proxy_server_cert_name => 'unified.wikimedia.org',
    proxy_backend => {
      'pmtpa' => { 'primary' => '10.2.1.25' },
      'eqiad' => { 'primary' => '10.2.2.25' },
      'esams' => { 'primary' => '10.2.3.25', 'secondary' => '208.80.152.202' },
      },
    ipv6_enabled => true,
    enabled => true,
  }
  proxy_configuration{ 'wikiquote':
    proxy_addresses => {
      'pmtpa' => [ '208.80.152.203', '[2620:0:860:ed1a::3]' ],
      'eqiad' => [ '208.80.154.227', '[2620:0:861:ed1a::3]' ],
      'esams' => [ '91.198.174.227', '[2620:0:862:ed1a::3]' ],
      },
    proxy_server_name => '*.wikiquote.org',
    proxy_server_cert_name => 'unified.wikimedia.org',
    proxy_backend => {
      'pmtpa' => { 'primary' => '10.2.1.25' },
      'eqiad' => { 'primary' => '10.2.2.25' },
      'esams' => { 'primary' => '10.2.3.25', 'secondary' => '208.80.152.203' },
      },
    ipv6_enabled => true,
    enabled => true,
  }
  proxy_configuration{ 'wikibooks':
    proxy_addresses => {
      'pmtpa' => [ '208.80.152.204', '[2620:0:860:ed1a::4]' ],
      'eqiad' => [ '208.80.154.228', '[2620:0:861:ed1a::4]' ],
      'esams' => [ '91.198.174.228', '[2620:0:862:ed1a::4]' ],
      },
    proxy_server_name => '*.wikibooks.org',
    proxy_server_cert_name => 'unified.wikimedia.org',
    proxy_backend => {
      'pmtpa' => { 'primary' => '10.2.1.25' },
      'eqiad' => { 'primary' => '10.2.2.25' },
      'esams' => { 'primary' => '10.2.3.25', 'secondary' => '208.80.152.204' },
      },
    ipv6_enabled => true,
    enabled => true,
  }
  proxy_configuration{ 'wikisource':
    proxy_addresses => {
      'pmtpa' => [ '208.80.152.205', '[2620:0:860:ed1a::5]' ],
      'eqiad' => [ '208.80.154.229', '[2620:0:861:ed1a::5]' ],
      'esams' => [ '91.198.174.229', '[2620:0:862:ed1a::5]' ],
      },
    proxy_server_name => '*.wikisource.org',
    proxy_server_cert_name => 'unified.wikimedia.org',
    proxy_backend => {
      'pmtpa' => { 'primary' => '10.2.1.25' },
      'eqiad' => { 'primary' => '10.2.2.25' },
      'esams' => { 'primary' => '10.2.3.25', 'secondary' => '208.80.152.205' },
      },
    ipv6_enabled => true,
    enabled => true,
  }
  proxy_configuration{ 'wikinews':
    proxy_addresses => {
      'pmtpa' => [ '208.80.152.206', '[2620:0:860:ed1a::6]' ],
      'eqiad' => [ '208.80.154.230', '[2620:0:861:ed1a::6]' ],
      'esams' => [ '91.198.174.230', '[2620:0:862:ed1a::6]' ],
      },
    proxy_server_name => '*.wikinews.org',
    proxy_server_cert_name => 'unified.wikimedia.org',
    proxy_backend => {
      'pmtpa' => { 'primary' => '10.2.1.25' },
      'eqiad' => { 'primary' => '10.2.2.25' },
      'esams' => { 'primary' => '10.2.3.25', 'secondary' => '208.80.152.206' },
      },
    ipv6_enabled => true,
    enabled => true,
  }
  proxy_configuration{ 'wikiversity':
    proxy_addresses => {
      'pmtpa' => [ '208.80.152.207', '[2620:0:860:ed1a::7]' ],
      'eqiad' => [ '208.80.154.231', '[2620:0:861:ed1a::7]' ],
      'esams' => [ '91.198.174.231', '[2620:0:862:ed1a::7]' ],
      },
    proxy_server_name => '*.wikiversity.org',
    proxy_server_cert_name => 'unified.wikimedia.org',
    proxy_backend => {
      'pmtpa' => { 'primary' => '10.2.1.25' },
      'eqiad' => { 'primary' => '10.2.2.25' },
      'esams' => { 'primary' => '10.2.3.25', 'secondary' => '208.80.152.207' },
      },
    ipv6_enabled => true,
    enabled => true,
  }
  proxy_configuration{ 'mediawiki':
    proxy_addresses => {
      'pmtpa' => [ '208.80.152.208', '[2620:0:860:ed1a::8]' ],
      'eqiad' => [ '208.80.154.232', '[2620:0:861:ed1a::8]' ],
      'esams' => [ '91.198.174.232', '[2620:0:862:ed1a::8]' ],
      },
    proxy_server_name => '*.mediawiki.org',
    proxy_server_cert_name => 'unified.wikimedia.org',
    proxy_backend => {
      'pmtpa' => { 'primary' => '10.2.1.25' },
      'eqiad' => { 'primary' => '10.2.2.25' },
      'esams' => { 'primary' => '10.2.3.25', 'secondary' => '208.80.152.208' },
      },
    ipv6_enabled => true,
    enabled => true,
  }
  proxy_configuration{ 'wikimediafoundation':
    proxy_addresses => {
      'pmtpa' => [ '208.80.152.209', '[2620:0:860:ed1a::9]' ],
      'eqiad' => [ '208.80.154.233', '[2620:0:861:ed1a::9]' ],
      'esams' => [ '91.198.174.235', '[2620:0:862:ed1a::9]' ],
      },
    proxy_server_name => '*.wikimediafoundation.org',
    proxy_server_cert_name => 'unified.wikimedia.org',
    proxy_backend => {
      'pmtpa' => { 'primary' => '10.2.1.25' },
      'eqiad' => { 'primary' => '10.2.2.25' },
      'esams' => { 'primary' => '10.2.3.25', 'secondary' => '208.80.152.209' },
      },
    ipv6_enabled => true,
    enabled => true,
  }
  proxy_configuration{ 'mobilewikipedia':
    proxy_addresses => {
      'pmtpa' => [ '127.0.0.1', '[2620:0:860:ed1a::c]' ],
      'eqiad' => [ '208.80.154.236', '[2620:0:861:ed1a::c]' ],
      'esams' => [ '127.0.0.1', '[2620:0:862:ed1a::c]' ],
    },
    proxy_server_name => '*.m.wikipedia.org',
    proxy_server_cert_name => 'unified.wikimedia.org',
    proxy_backend => {
      'pmtpa' => { 'primary' => '10.2.1.26' },
      'eqiad' => { 'primary' => '10.2.2.26' },
      'esams' => { 'primary' => '10.2.3.26', 'secondary' => '208.80.154.236' },
    },
    ipv6_enabled => true,
    enabled => true,
  }
  # wikidata.org
  if $::site != 'esams' {
    proxy_configuration{ 'wikidata':
      proxy_addresses => {
        'pmtpa' => [ '208.80.152.218', '[2620:0:860:ed1a::12]' ],
        'eqiad' => [ '208.80.154.242', '[2620:0:861:ed1a::12]' ],
        # 'esams' => [ '127.0.0.1' ],
      },
      proxy_server_name => '*.wikidata.org',
      proxy_server_cert_name => 'unified.wikimedia.org',
      proxy_backend => {
        'pmtpa' => { 'primary' => '10.2.1.25' },
        'eqiad' => { 'primary' => '10.2.2.25' },
        # 'esams' => { 'primary' => '10.2.3.25' },
      },
      ipv6_enabled => true,
      enabled => true,
    }
  }
  # wikivoyage.org
  if $::site != 'esams' {
    proxy_configuration{ 'wikivoyage':
      proxy_addresses => {
        'pmtpa' => [ '208.80.152.219', '[2620:0:860:ed1a::13]' ],
        'eqiad' => [ '208.80.154.243', '[2620:0:861:ed1a::13]' ],
        # 'esams' => [ '127.0.0.1' ],
      },
      proxy_server_name => '*.wikivoyage.org',
      proxy_server_cert_name => 'unified.wikimedia.org',
      proxy_backend => {
        'pmtpa' => { 'primary' => '10.2.1.25' },
        'eqiad' => { 'primary' => '10.2.2.25' },
        # 'esams' => { 'primary' => '10.2.3.25' },
      },
      ipv6_enabled => true,
      enabled => true,
    }
  }
  # Misc services
  proxy_configuration{ 'videos':
    proxy_addresses => {
      'pmtpa' => [ '208.80.152.200', '[2620:0:860:2::80:2]' ],
      'eqiad' => [ '208.80.154.224', '[2620:0:862:3::80:2]' ],
      'esams' => [ '91.198.174.224', '[2620:0:862:1::80:2]' ] },
    proxy_server_name => 'videos.wikimedia.org',
    proxy_server_cert_name => 'unified.wikimedia.org',
    proxy_backend => {
      'pmtpa' => { 'primary' => '10.64.16.146' },
      'eqiad' => { 'primary' => '10.64.16.146' },
      'esams' => { 'primary' => '208.80.152.200', 'secondary' => '208.80.152.200' },
      },
    ssl_backend => { 'esams' => 'true' },
    enabled => true,
  }

}

class protoproxy::package {

  package { ['nginx']:
    ensure => latest,
  }

  file { '/etc/nginx/sites-enabled/default':
    ensure => absent,
  }

}

class protoproxy::service {
  require protoproxy::proxy_sites

  service { ['nginx']:
    ensure => running,
    enable => true,
  }
}

class protoproxy::ganglia {
  file { '/usr/lib/ganglia/python_modules/apache_status.py':
    source => 'puppet:///files/ganglia/plugins/apache_status.py',
    notify => Service[gmond],
  }
  file { '/etc/ganglia/conf.d/apache_status.pyconf':
    source => 'puppet:///files/ganglia/plugins/apache_status.pyconf',
    notify => Service[gmond],
  }
}
