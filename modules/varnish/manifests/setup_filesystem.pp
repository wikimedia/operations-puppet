define varnish::setup_filesystem() {
    $mount_options = $::realm ? {
        'production' => 'noatime,nodiratime,nobarrier,logbufs=8',
        'labs'       => 'noatime,nodiratime,nobarrier,comment=cloudconfig',
    }

    if $::realm == 'labs' {
      include labs_lvm
      labs_lvm::volume { $title:
        mountat => "/srv/${title}",
        options => $mount_options,
      }
    } else {
      file { "/srv/${title}":
          ensure => directory,
          owner  => 'root',
          group  => 'root',
      }

      mount { "/srv/${title}":
          ensure  => mounted,
          require => File["/srv/${title}"],
          device  => "/dev/${title}",
          fstype  => 'auto',
          options => $mount_options,
      }
    }
}
