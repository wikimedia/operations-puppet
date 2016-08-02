# Role class for a DRBD client
#
class role::labs::labstore::drbd_node {

    # Make sure drbd is installed
    # Installing this package also sets up a systemd init script in /etc/init.d
    ensure_packages(['drbd8-utils',])

    # Bootstrap resource configs
    # Let's start with taking everything in files/labs/labstore/drbd-conf and copying
    # them onto /etc/drbd.d/ in the machine. Need to think about whether having a
    # puppet define for a drbd resource is more useful, and if resource definitions
    # themselves can do with more templatization
    file { '/etc/drbd.d/':
        ensure        => directory,
        source        => 'puppet:///modules/role/labs/labstore/drbd-conf/',
        sourceselect  => all,
    }

    # Ensure that the service is running
    base::service_unit { 'drbd':
        ensure          => present,
        service_params  => {
            hasrestart => true,
            hasstatus  => true,
            path       => '/etc/init.d' #Need to specify?
        }
    }


}
