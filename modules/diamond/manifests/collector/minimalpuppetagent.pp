# == Define: diamond::collector::minimalpuppetagent
#
# Configures a minimal puppet agent collector
# that collects just time since last puppet run
# and total time it took for puppet to run
#
# Note: Requires puppet 3+ since older puppet did
# not make the required summary yaml file world readable
#
define diamond::collector::minimalpuppetagent {
    ensure_packages(['python-yaml'])

    # Diamond user needs sudo to access puppet
    admin::sudo { 'diamond_sudo_for_puppet':
        user    => 'diamond',
        comment => 'diamond needs sudo to access exim mail queue length',
        privs   => ['ALL=(root) NOPASSWD: "/bin/cat /var/lib/puppet/state/last_run_summary.yaml"']
    }


    diamond::collector { 'MinimalPuppetAgent':
        source  => 'puppet:///modules/diamond/collector/minimalpuppetagent.py',
        require => Package['python-yaml'],
    }
}
