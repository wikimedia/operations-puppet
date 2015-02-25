define varnish::setup_filesystem() {
    $base_mount_options = "noatime"

    if $::realm == 'labs' and $::site == 'eqiad' {
        # XXX we probably want to switch these off XFS as well,
        #  but I'm unsure of the process here and what might
        #  break if I change the definition for running instances...
        include labs_lvm
        labs_lvm::volume { $title:
            mountat => "/srv/${title}",
            options => "$base_mount_options,comment=cloudconfig",
            fstype  => 'xfs',
        }
    } else {
        if os_version('debian >= jessie') {
            # setup_filesystem is only used on the non-bits caches,
            #  which are all set up as ext4-on-SSD...
            $mount_options = "$base_mount_options,nobarrier,data=writeback,discard"

            # For the new jessie setup, we mkfs here post-install as well if the
            #  label hasn't already been set during previous mkfs...
            exec { "mkfs-${title}-varnish":
                command => "/sbin/mke2fs -F -F -t ext4 -T huge -O sparse_super2 -m 0 -L ${title}-varnish /dev/${title}",
                unless => "/sbin/e2label /dev/${title} 2>/dev/null | grep -q '^${title}-varnish$'",
                before => Mount["/srv/${title}"],
            }
        }
        else {
            # nodiratime is redundant, but I'm hoping to avoid
            #  pointless puppet-triggered remount attempts on
            #  the legacy boxes here...
            $mount_options = "$base_mount_options,nodiratime,nobarrier,logbufs=8"
        }

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
