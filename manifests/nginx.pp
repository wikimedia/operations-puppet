#nginx.pp
class nginx::install {
  package { [ "nginx" ]:
  ensure => present;
  }
}

class nginx::service {
  service { "nginx":
     ensure => running,
     hasstatus => true,
     hasrestart => true,
     enable => true,
     require => Class["nginx::install"];
   }
}

class nginx::proxy {
     file { 
       "/etc/nginx/sites-available/proxy":
          ensure => present,
          source => "puppet:///files/nginx/proxy",
          owner => "root",
          group => "root",
          require => Class["nginx::install"];
    
       "/etc/nginx/sites-enabled/proxy":
          ensure => 'link',
          target => '/etc/nginx/sites-available/proxy',
          notify => Class["nginx::service"];
    }
}

