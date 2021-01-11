# == Class profile::pybal::testing
#
# Class for a pybal test host
#
class profile::pybal::testing(
    String $pybal_site = lookup(pybal::configuration::site, {default_value => 'eqiad'}),
    String $pybal_config = lookup(pybal::configuration::config, {default_value => 'http'}),
    String $pybal_config_host = lookup(pybal::configuration::config_host, {default_value => 'config-master.eqiad.wmnet'}),
){
    $opts = {
        'instrumentation' => 'yes',
        'bgp'             => 'no',
        'dry-run'         => 'yes',
    }
    # TODO: fix this.\
    $services = wmflib::service::get_services_for_lvs('secondary', $::site)

    $lvs_class_hosts_stub = {
        'high-traffic1' => [$::hostname],
        'high-traffic2' => [$::hostname],
        'low-traffic'   => [$::hostname],
    }
    class { 'pybal::configuration':
        global_options  => $opts,
        services        => $services,
        lvs_class_hosts => $lvs_class_hosts_stub,
        site            => $pybal_site,
        config          => $pybal_config,
        config_host     => $pybal_config_host,
    }
}
