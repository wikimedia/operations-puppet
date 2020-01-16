class role::repositoryserver {
    system::role { 'repositoryserver': }

    include ::profile::standard
    include ::profile::base::firewall
    include ::profile::backup::host

    include ::profile::aptrepo::wikimedia
}
