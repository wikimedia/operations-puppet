define kubeadm::package_from_component (
    Enum['1.15']  $version  = '1.15',
    Array[String] $packages = [$name],
) {
    if $version == '1.15' {
        $component = 'thirdparty/kubeadm-k8s-1-15'
    } else {
        fail('unknown version')
    }

    apt::package_from_component { "${name}-${version}":
        distro    => 'buster-wikimedia', # be explicit so we support stretch
        component => $component,
        packages  => $packages,
    }
}
