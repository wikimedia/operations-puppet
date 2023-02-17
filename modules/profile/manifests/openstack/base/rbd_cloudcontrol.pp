# SPDX-License-Identifier: Apache-2.0
# Configure rbd/ceph for glance and radosgw
#
# Both services require config in the same files 
class profile::openstack::base::rbd_cloudcontrol(
    Stdlib::Fqdn        $keystone_fqdn                = lookup('profile::openstack::base::keystone_api_fqdn'),
    Stdlib::Port        $internal_auth_port           = lookup('profile::openstack::base::keystone::internal_port'),
    Stdlib::Port        $api_bind_port                = lookup('profile::openstack::base::radosgw::api_bind_port'),
    String              $radosgw_service_user_pass    = lookup('profile::openstack::base::radosgw::service_user_pass'),
    String              $radosgw_service_user         = lookup('profile::openstack::base::radosgw::service_user'),
    String              $radosgw_service_user_project = lookup('profile::openstack::base::radosgw::service_user_project'),
    ) {

    $keystone_internal_uri = "https://${keystone_fqdn}:${internal_auth_port}"

    # Many of the settings for this class will be pulled in by the profile
    #  and are DC-specific but not deloyment-specific.  If/when we add a new
    #  region with a new ceph cluster they will need to be overridden
    #  with deployment-specific hiera.
    class { 'profile::cloudceph::client::rbd_cloudcontrol':
        radosgw_port                 => $api_bind_port,
        keystone_internal_uri        => $keystone_internal_uri,
        radosgw_service_user         => $radosgw_service_user,
        radosgw_service_user_project => $radosgw_service_user_project,
        radosgw_service_user_pass    => $radosgw_service_user_pass,
    }
}
