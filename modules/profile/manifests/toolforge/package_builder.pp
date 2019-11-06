# == Class: profile::package::builder
#
# Profile for Toolforge package builder
#
class profile::toolforge::package_builder(
){
    class { '::package_builder': }

    # Packages needed by the packages used in toolforge
    require_package(
        'python-all',
        'sbuild',
    )
}
