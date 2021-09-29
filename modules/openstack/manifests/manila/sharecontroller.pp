# NOTE:
# this is for a virtual machine running on CloudVPS
# the virtual machine will run the manila-share service
# acting as a controller for other service VMs created for
# actual NFS shares
#
class openstack::manila::sharecontroller (
    Boolean $enabled,
    String  $version,
) {
    require "openstack::clientpackages::vms::${version}::${::lsbdistcodename}"
    require openstack::manila::configuration
    requires_realm('labs')

    require_package('manila-share')

    service { 'manila-share':
        ensure    => $enabled,
        require   => Package['manila-share'],
        subscribe => File['/etc/manila/manila.conf'],
    }
}
