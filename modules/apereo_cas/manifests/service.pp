define apereo_cas::service (
    String         $class,
    Integer        $id,
    String         $service_id,
    Hash           $attribute_release_policy,
    Hash           $access_strategy,
    Optional[Hash] $properties = {}
) {
    include apereo_cas
    $base_data = {
        '@class'                 => $class,
        'name'                   => $title,
        'serviceId'              => $service_id,
        'attributeReleasePolicy' => $attribute_release_policy,
        'id'                     => $id,
        'accessStrategy'         => $access_strategy,
    }
    $data = $properties.empty ? {
        true    => $base_data,
        default => $base_data + $properties,
    }
    file {"${apereo_cas::services_dir}/${title}-${id}.json":
        ensure  => file,
        content => $data.to_json()
    }
}
