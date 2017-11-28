# == Define: prometheus::pdu_config
#
# Generate prometheus targets configuration for all PDUs in a given site.

# == Parameters
# $dest:    The output file where to write the result.
# $site:    The site to filter on.
# $labels:  Labels to attach to every target. 'row' will be added from
# discovered resources.

define prometheus::pdu_config(
    $dest,
    $site,
    $labels = {},
) {
    validate_string($dest)
    validate_string($site)
    validate_hash($labels)

    $pdu_resources = query_resources(false, 'Facilities::Monitor_pdu_3phase', false)

    file { $dest:
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('prometheus/pdu_config.erb'),
    }
}
