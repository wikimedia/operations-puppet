function wmflib::service::get_ips_for_services(
    Hash[String, Wmflib::Service] $services,
    String $site,
) >> Array[Stdlib::IP::Address] {
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
