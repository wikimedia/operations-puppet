# This function retrieves the services list from hiera.
# In the future, this function should include all validation that is not doable
# with basic puppet typing.
# Takes a Boolean parameter called lvs.
# If set to true, only LVS based services will be returned.
# If set to false, all services will be returned
function wmflib::service::fetch(
    Boolean $lvs_only=false,
) >> Hash[String, Wmflib::Service] {
    # Use when doing local development
    #$yaml = loadyaml('hieradata/common/service.yaml')
    #$catalog = $yaml['service::catalog']
    include wmflib::service::catalog

    $lvs_only ? {
        true    => $wmflib::service::catalog::pools_lvs,
        default => $wmflib::service::catalog::pools,
    }
}
