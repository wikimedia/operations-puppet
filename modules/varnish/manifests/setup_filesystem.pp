define varnish::setup_filesystem() {
    if $::realm == 'labs' {
        $custom_mount_opts = ',comment=cloudconfig'
    }
    elsif os_version('debian >= jessie') {
        # setup_filesystem is only used on the non-bits caches,
        #  which are all set up as ext4-on-SSD...
        $custom_mount_opts = ',nobarrier,data=writeback,discard'
    }
    else {
        # nodiratime is redundant, but I'm hoping to avoid
        #  pointless puppet-triggered remount attempts on
        #  the legacy boxes here...
        $custom_mount_opts = ',nodiratime,nobarrier,logbufs=8'
    }

    $mount_options = "noatime$custom_mount_opts"

    if $::realm == 'labs' and $::site == 'eqiad' {
      include labs_lvm
      labs_lvm::volume { $title:
        mountat => "/srv/${title}",
        options => $mount_options,
        fstype  => 'xfs',
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
