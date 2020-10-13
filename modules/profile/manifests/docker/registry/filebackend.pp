class profile::docker::registry::filebackend(
    Hash $config = lookup('profile::docker::registry::config', {default_value => {}}),
    Stdlib::Unixpath $datapath = lookup('profile::docker::registry::datapath', {default_value => '/srv/registry'}),
) {
    class { '::docker::registry':
        config   => $config,
        datapath => $datapath,
    }
}
