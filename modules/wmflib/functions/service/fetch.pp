# This function retrieves the services list from hiera.
# In the future, this function should include all validation that is not doable
# with basic puppet typing.
function wmflib::service::fetch() >> Hash[String, Wmflib::Service] {
    # Use when doing local development
    #$yaml = loadyaml('hieradata/common/service.yaml')
    #$catalog = $yaml['service::catalog']

    $catalog = lookup('service::catalog', {'default_value' => {}})
    wmflib::service::validate($catalog)
    return $catalog
}
