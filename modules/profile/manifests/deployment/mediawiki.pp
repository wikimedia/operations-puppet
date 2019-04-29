class profile::deployment::mediawiki(
    Array[String] $deployment_hosts = hiera('deployment_hosts', []),
) {
    class { '::scap::master':
        deployment_hosts => $deployment_hosts,
    }
}
