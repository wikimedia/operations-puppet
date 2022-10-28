# SPDX-License-Identifier: Apache-2.0
#
# This define can be used to install a package for a specific kubernetes version from
# our internal apt repository.
#
define k8s::package (
    Enum['master', 'node', 'client'] $package,
    K8s::KubernetesVersion           $version         = '1.16',
    String                           $distro          = "${::lsbdistcodename}-wikimedia",
    Stdlib::HTTPUrl                  $uri             = 'http://apt.wikimedia.org/wikimedia',
    Integer                          $priority        = 1001,
    Boolean                          $ensure_packages = true,
) {
    $component = "kubernetes${regsubst($version, '\\.', '')}"
    apt::package_from_component { "${title}-${component}":
        component => "component/${component}",
        packages  => ["kubernetes-${package}"],
    }
}
