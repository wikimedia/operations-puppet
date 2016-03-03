# == Define: service::packages
#
# service::packages is a simple define allowing service modules to list all of
# their debian package dependencies - both for normal, production use and those
# needed by the service to build / compile its (binary) dependencies. A service
# simply lists all of its dependencies, but the
# ::service::configuration::use_dev_pkgs flag controls whether the development
# libraries will be included in the install or not.
#
# === Parameters
#
# [*pkgs*]
#   An array containing the list of packages that are needed by a service to
#   function in all environments. Default: undef
#
# [*dev_pkgs*]
#   An array holding the list of development packages needed when building the
#   service's dependencies. Default: undef
#
define service::packages(
    $pkgs = undef,
    $dev_pkgs = undef,
) {

    require ::service::configuration
    $use_dev = $::service::configuration::use_dev_pkgs

    # it is possible for a service not to have run-time dependencies while still
    # having compile-time ones, so ensure we are actually requiring something
    if is_array($pkgs) and size($pkgs) > 0 {
        require_package($pkgs)
    }

    if $use_dev and is_array($dev_pkgs) and size($dev_pkgs) > 0 {
        require_package($dev_pkgs)
    }

}
