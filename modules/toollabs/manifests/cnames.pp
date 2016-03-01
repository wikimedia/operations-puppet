# = Class: toollabs::cnames
# Various CNAMEs used by tool labs
# Used in the labs dnsrecursor role. Hiera for this will need to be hence set
# in ops/puppet rather than wikitech.
class toollabs::cnames(
    $docker_registry,
) {
    file { '/var/zones/tools.eqiad.wmflabs':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        content => template('toollabs/cnames.erb')
    }
}
