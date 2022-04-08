class profile::conftool::requestctl_client(
        String $conftool_prefix = lookup('conftool_prefix'),
) {
    require profile::conftool::client
    ensure_packages(['python3-conftool-requestctl'])
    # Create the test directory
    file { ['/var/lib/requestctl', '/var/lib/requestctl/tests']:
        ensure => directory,
    }
    # TODO: add an alert if there are uncommitted changes
}
