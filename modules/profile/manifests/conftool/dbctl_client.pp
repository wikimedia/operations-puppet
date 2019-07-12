class profile::conftool::dbctl_client() {
    require ::profile::conftool::client

    require_package('python3-conftool-dbctl')
}
