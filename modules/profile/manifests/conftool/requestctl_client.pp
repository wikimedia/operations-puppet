class profile::conftool::requestctl_client() {
    require profile::conftool::client
    ensure_packages(['python3-conftool-requestctl'])
    # TODO: add an alert if there are uncommitted changes
}
