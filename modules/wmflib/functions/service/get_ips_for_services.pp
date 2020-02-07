function wmflib::service::get_ips_for_services(
    Hash[String, Wmflib::Service] $services,
    String $site,
) >> Array[Stdlib::Ip_address] {
    $services.filter |$lvs_name, $svc| {
        $site in $svc['ip']
    }
    .map |$lvs_name, $svc| {
        $svc['ip'][$site].values()
    }
    .flatten()
    .unique()
    .sort()
}
