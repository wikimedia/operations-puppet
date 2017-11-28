class profile::docker::registry::filebackend(
    $config = hiera('profile::docker::registry::config', {}),
    $datapath = hiera('profile::docker::registry::datapath', '/srv/registry'),
) {
    class { '::docker::registry':
        config   => $config,
        datapath => $datapath,
    }
}
