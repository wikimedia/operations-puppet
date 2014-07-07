# == Define: diamond::collector::minimalpuppetagent
#
# Configures a minimal puppet agent collector
# that collects just time since last puppet run
# and total time it took for puppet to run
#
define diamond::collector::minimalpuppetagent {
    ensure_packages(['python-yaml'])

    # Diamond user needs sudo to access last_run_summary.yaml file generated by
    # puppet, since /var/lib/puppet doesn't have +x set
    admin::sudo { 'diamond_sudo_for_puppet':
        user    => 'diamond',
        comment => "diamond needs sudo to access puppet's last_run_summary.yaml file",
        privs   => ['ALL=(puppet) NOPASSWD: /bin/cat /var/lib/puppet/state/last_run_summary.yaml']
    }


    diamond::collector { 'MinimalPuppetAgent':
        source  => 'puppet:///modules/diamond/collector/minimalpuppetagent.py',
        require => Package['python-yaml'],
    }
}
