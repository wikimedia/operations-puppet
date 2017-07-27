# vim: set tabstop=4 shiftwidth=4 softtabstop=4 expandtab textwidth=80 smarttab
# This is the old puppetmaster class running on labcontrol1001.  It's being phased out
#  in favor of labs:puppetmasterfrontend and labs:puppetmasterbackend

class role::labs::puppetmaster(
    $use_enc = true,
) {

    include network::constants
    include ldap::role::config::labs
    include puppetmaster::labsrootpass

    $labs_metal = hiera('labs_baremetal_servers', [])
    $novaconfig = hiera_hash('novaconfig', {})
    $labs_instance_range = $novaconfig['fixed_range']
    $horizon_host = hiera('labs_horizon_host')
    $horizon_host_ip = ipresolve(hiera('labs_horizon_host'), 4)
    $designate_host_ip = ipresolve(hiera('labs_designate_hostname'), 4)
    # Only allow puppet access from the instances
    $allow_from = flatten([$labs_instance_range, '208.80.154.14', '208.80.155.119', '208.80.153.74', $horizon_host_ip, $labs_metal])

    class { 'role::puppetmaster::standalone':
        autosign            => true,
        # FIXME: Temporarily set to false until we make git-sync-upstream
        # work as non-root.
        prevent_cherrypicks => false,
        allow_from          => $allow_from,
        git_sync_minutes    => '1',
        use_enc             => $use_enc,
        extra_auth_rules    => template('role/labs/puppetmaster/extra_auth_rules.conf.erb'),
        server_name         => hiera('labs_puppet_master'),

    }

    if ! defined(Class['puppetmaster::certmanager']) {
        class { 'puppetmaster::certmanager':
            remote_cert_cleaner => hiera('labs_certmanager_hostname'),
        }
    }

    include labspuppetbackend

    $labs_vms = $novaconfig['fixed_range']
    $monitoring = '208.80.154.14 208.80.155.119 208.80.153.74'

    # temporarily open up the enc to the old puppetmasters.
    # I hate this, but the enc url is hardcoded in hiera.yaml and difficult
    # to modify per puppetmaster.
    #  FIXME:  Remove this after we've standardized on labs-puppetmaster.wikimedia.org
    $new_puppetmasters = '208.80.154.158 208.80.155.120'

    $fwrules = {
        puppetmaster => {
            rule => "saddr (${labs_vms} ${labs_metal} ${monitoring} ${horizon_host_ip}) proto tcp dport 8140 ACCEPT;",
        },
        puppetbackend => {
            rule => "saddr (${horizon_host_ip} ${designate_host_ip}) proto tcp dport 8101 ACCEPT;",
        },
        puppetbackendgetter => {
            rule => "saddr (${labs_vms} ${labs_metal} ${monitoring} ${horizon_host_ip} ${new_puppetmasters}) proto tcp dport 8100 ACCEPT;",
        },
    }
    create_resources (ferm::rule, $fwrules)
}
