# SPDX-License-Identifier: Apache-2.0
class profile::base::netbase(
    Boolean                       $manage_etc_services = lookup('profile::base::netbase::manage_etc_services'),
    Hash[String,Netbase::Service] $extra_services      = lookup('profile::base::netbase::extra_services'),
) {
    # Need to create a function which parse the service catalogue to create a hash of
    # service definitions to pass to netbase
    $services = $extra_services # + wmflib::get_service_definitions()
    class {'netbase':
        services            => $services,
        manage_etc_services => $manage_etc_services,
    }
}
