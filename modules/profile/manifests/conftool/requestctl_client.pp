class profile::conftool::requestctl_client(
        String $conftool_prefix = lookup('conftool_prefix'),
) {
    require profile::conftool::client
    ensure_packages(['python3-conftool-requestctl'])
    # Create the test directory
    file { ['/var/lib/requestctl', '/var/lib/requestctl/tests']:
        ensure => directory,
    }

    # Install the per-cluster test files.
    ['text', 'upload'].each |$cache_cluster| {
        $is_test = true
        confd::file { "/var/lib/requestctl/tests/${cache_cluster}-actions.inc.vcl":
            ensure     => 'present',
            watch_keys => ['/request-patterns', "/request-actions/cache-${cache_cluster}"],
            content    => template('profile/cache/varnish-frontend-dynamic-actions.vcl.tpl.erb'),
        }
    }
    # TODO: add an alert if there are uncommitted changes
}
