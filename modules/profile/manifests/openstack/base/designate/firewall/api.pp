class profile::openstack::base::designate::firewall::api(
    Array[Stdlib::Fqdn] $labweb_hosts = lookup('profile::openstack::base::labweb_hosts'),
    Array[Stdlib::Fqdn] $openstack_controllers = lookup('profile::openstack::base::openstack_controllers'),
) {
    # Open designate API to WMCS web UIs and the commandline on control servers
    ferm::service { 'designate-tls-api':
        proto  => 'tcp',
        port   => '29001',
        srange => "(@resolve((${labweb_hosts.join(' ')} ${openstack_controllers.join(' ')}))",
    }

    # Allow labs instances to hit the designate api.
    # This is not as permissive as it looks; The wmfkeystoneauth
    # plugin (via the password whitelist) only allows 'novaobserver'
    # to authenticate from within labs, and the novaobserver is
    # limited by the designate policy.json to read-only queries.
    ferm::service { 'designate-tls-api-for-labs':
        proto  => 'tcp',
        port   => '29001',
        srange => '$LABS_NETWORKS',
    }
}
