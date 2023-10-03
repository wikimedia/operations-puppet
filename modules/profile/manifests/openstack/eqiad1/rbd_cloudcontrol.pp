# SPDX-License-Identifier: Apache-2.0
class profile::openstack::eqiad1::rbd_cloudcontrol(
    Stdlib::Fqdn        $keystone_fqdn             = lookup('profile::openstack::eqiad1::keystone_api_fqdn'),
    String              $radosgw_service_user_pass = lookup('profile::openstack::eqiad1::radosgw::service_user_pass'),
    ) {

    # Many of the settings for this class will be pulled in by the profile
    #  and are DC-specific but not deloyment-specific.  If/when we add a new
    #  region with a new ceph cluster they will need to be overridden
    #  with deployment-specific hiera.
    class { '::profile::openstack::base::rbd_cloudcontrol':
        keystone_fqdn             => $keystone_fqdn,
        radosgw_service_user_pass => $radosgw_service_user_pass,
    }
}
