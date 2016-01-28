# == Define: grafana::dashboard
#
# Provisions a Grafana dashboard definition. Grafana dashboards may
# be defined via the web interface, or by placing a JSON dashboard
# definition in Grafana's dashboard directory. This resource is meant
# to help you do the latter.
#
# The Grafana JSON format is not documented, but you can see what
# it looks like by creating or loading a dashboard in Grafana and
# then using the "export" feature to see the dashboard's JSON
# representation.
#
# === Parameters
#
# [*content*]
#   If defined, will be used as the content of the dashboard JSON
#   file. Undefined by default. Mutually exclusive with 'source'.
#
# [*source*]
#   Path to file containing JSON dashboard definition. Undefined
#   by default. Mutually exclusive with 'content'.
#
# === Examples
#
#  grafana::dashboard { 'reqerror':
#    source => 'puppet:///modules/varnish/dashboards/reqerror.json',
#  }
#
define grafana::dashboard(
    $content = undef,
    $source  = undef,
) {
    include ::grafana

    $basename = regsubst($title, '\W', '-', 'G')

    if ( $source == undef and $content == undef ) or ( $source != undef and $content != undef ) {
        fail('you must provide either "source" or "content" (but not both)')
    }

    file { "/var/lib/grafana/dashboards/${basename}.json":
        ensure  => $::ensure,
        content => $content,
        source  => $source,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service['grafana-server'],
    }
}
