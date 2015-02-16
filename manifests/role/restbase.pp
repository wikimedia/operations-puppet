# == Class role::restbase
#

@monitoring::group { 'restbase_eqiad': description => 'Restbase eqiad' }

# Config should be pulled from hiera
class role::restbase {
    system::role { 'restbase': description => "Restbase ${::realm}" }

    include ::restbase

    include lvs::configuration
    class { 'lvs::realserver': realserver_ips => $lvs::configuration::lvs_service_ips[$::realm]['restbase'][$::site] }
}
