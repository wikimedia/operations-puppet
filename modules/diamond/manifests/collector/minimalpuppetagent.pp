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

    # Currently, /var/lib/puppet is set to have no permissions for o,
    # causing diamond to not be able to read the last_run_summary.yaml
    # file despite that file having appropriate permissions set by
    # puppet. This ensures that diamond can actually read that file.
    # Guard against puppetmasters, where the same directory is
    # defined with the same permissions
    if ! is_puppet_master {
        file { '/var/lib/puppet':
            mode   => '0751',
            ensure => present,
            notify => Service['diamond']
        }
    }

    diamond::collector { 'MinimalPuppetAgent':
        source  => 'puppet:///modules/diamond/collector/minimalpuppetagent.py',
        require => Package['python-yaml'],
    }
}
