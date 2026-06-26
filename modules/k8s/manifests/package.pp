# SPDX-License-Identifier: Apache-2.0
#
# This define can be used to install a package for a specific kubernetes version from
# our internal apt repository.
#
define k8s::package (
    Enum['master', 'node', 'client'] $package,
    K8s::KubernetesVersion           $version,
    String                           $distro          = "${facts['os']['distro']['codename']}-wikimedia",
    Stdlib::HTTPUrl                  $uri             = 'http://apt.wikimedia.org/wikimedia',
    Integer                          $priority        = 1001,
    Boolean                          $ensure_packages = true,
) {
    require k8s::base_dirs
    $version_no_dot = regsubst($version, '\\.', '')
    $version_array = $version.split('\\.')
    $minor_version = Integer($version_array[1])
    $next_version = "${$version_array[0]}.${$minor_version + 1}"
    $component_title = "kubernetes${version_no_dot}"
    ensure_resource('apt::package_from_component', $component_title, {
        component => "component/${component_title}",
        packages  => [],
    })
    if $package == 'client' {
        # The kubernetes-client package (e.g. kubectl) carries the k8s version number in it's
        # package name so that we can install multiple kubectl versions in parallel
        $package_name = "kubernetes-client${version_no_dot}"
    } else {
        $package_name = "kubernetes-${package}"
    }
    ensure_packages($package_name, {
        'require' => Apt::Package_from_component[$component_title],
        'ensure'  => ">=${version} <${next_version}"
    })
}
