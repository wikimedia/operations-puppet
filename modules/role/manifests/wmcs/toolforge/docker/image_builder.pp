class role::wmcs::toolforge::docker::image_builder(
) {
    system::role { $name: }

    include profile::toolforge::base
    include profile::toolforge::infrastructure
    include profile::toolforge::docker::image_builder
}
