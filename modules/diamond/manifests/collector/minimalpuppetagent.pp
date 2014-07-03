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
    # Uses an exec rather than a file since a file resource
    # with that name has already been defined elsewhere
    exec { 'make-puppet-statefile-readable':
        command => '/bin/chmod 0755 /var/lib/puppet',
        unless  => "/bin/sh -c '[ $(/usr/bin/stat -c %a /var/lib/puppet == 0755 ]'",
        notify  => Service['diamond']
    }

    diamond::collector { 'MinimalPuppetAgent':
        source  => 'puppet:///modules/diamond/collector/minimalpuppetagent.py',
        require => Package['python-yaml'],
    }
}
