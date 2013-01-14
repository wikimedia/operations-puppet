class nginx-proxy::config {
      file { "/etc/nginx/sites-available/proxy":
      ensure => present,
      source => "puppet:///modules/nginx-proxy/proxy",
      owner => "root",
      group => "root",
      require => Class["nginx-proxy::install"],
      notify => Class["nginx-proxy::service"],
    }
      file { '/etc/nginx/sites-enabled/proxy':
      ensure => 'link',
      target => '/etc/nginx/sites-available/proxy',
    }
}
