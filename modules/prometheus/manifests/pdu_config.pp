# == Define: prometheus::pdu_config
#
# Generate prometheus targets configuration for all PDUs in a given site.

# == Parameters
# $dest:    The output file where to write the result.
# $labels:  Labels to attach to every target. 'row' will be added from
# discovered resources.

define prometheus::pdu_config(
    String $dest,
    String $model    = 'sentry3',
    String $resource = 'Facilities::Monitor_pdu_3phase',
    Hash   $labels   = {},
) {

    $pql = @("PQL")
    resources[parameters, title] {
        type = "${resource}" and
        parameters.model = "${model}" and parameters.site = "${::site}"
        order by parameters
    }
    | PQL
    $pdu_resources = wmflib::puppetdb_query($pql)

    file { $dest:
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('prometheus/pdu_config.erb'),
    }
}
