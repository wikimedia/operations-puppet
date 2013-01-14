class nginx-proxy::service {
  service { "nginx":
     ensure => running,
     hasstatus => true,
     hasrestart => true,
     enable => true,
     require => Class["nginx-proxy::config"],
   }
}
