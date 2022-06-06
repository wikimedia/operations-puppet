# SPDX-License-Identifier: Apache-2.0
# @summary class to add a hash of service definitions to /etc/services
# @param services a hash of Netbase::Service definitions
# @param default_services a hash of Netbase::Service definitions
# @param append_aliases if true append aliases to the preferred input
class netbase (
    Hash[String,Netbase::Service] $services            = {},
    Hash[String,Netbase::Service] $default_services    = {},
    Boolean                       $append_aliases      = false,
    Boolean                       $manage_etc_services = true,
) {
    # we use the loose merge policy i.e. only test on port to ensure the default services always win
    $all_services = netbase::services::merge($services, $default_services, $append_aliases, false)
    if $manage_etc_services {
        file{'/etc/services':
            ensure  => 'file',
            owner   => 'root',
            group   => 'root',
            content => template('netbase/services.erb'),
        }
    }
}
