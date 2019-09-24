define apereo_cas::service (
    String  $class,
    Integer $id,
    String  $service_id,
    Hash    $attribute_release_policy
) {
    include apereo_cas
    $data = {
        '@class'                 => $class,
        'name'                   => $title,
        'serviceId'              => $service_id,
        'attributeReleasePolicy' => $attribute_release_policy,
    }
    file {"${apereo_cas::services_dir}/${title}-${id}.json":
        ensure  => file,
        content => $data.to_json()
    }
}
