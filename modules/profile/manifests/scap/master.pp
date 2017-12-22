# == Class profile::scap::master
#
# Sets up a scap master on a host
class profile::scap::master(
    $main_deployment_server = hiera('scap::deployment_server'),
) {
    class { '::scap::master':
        run_l10nupdate => ($main_deployment_server == $::fqdn)
    }
}
