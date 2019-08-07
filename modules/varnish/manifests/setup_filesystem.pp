define varnish::setup_filesystem() {
    if $::realm == 'labs' {
        $mount_options = 'noatime,comment=cloudconfig'
    }
    elsif os_version('debian >= stretch') {
        # Starting with stretch, we don't use the journal at mke2fs time
        $mount_options = 'noatime,nobarrier'
    }

    if $::realm == 'labs' and $::site == 'eqiad' {
      include ::labs_lvm
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
