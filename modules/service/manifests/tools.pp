# == Class: service::tools
# scripts and tools that are useful for all services,
# such as global restart and helper scripts
# 
# === Parameters
#
# [*cluster*]
#   Which set of services to use. (currently 'sca' or 'scb')
#   Default: none. required.
class service::tools(
    $cluster,
){

    # TODO, hiera lookup based on $cluster
    $service_names = hiera('role::common::${cluster}::service_names', ''), 

    # script to restart all services in a service group
    file { '/usr/local/sbin/restart-services':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0550',
	content => template('service/restart-services.erb'),
    }

}
