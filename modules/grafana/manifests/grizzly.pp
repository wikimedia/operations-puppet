# grizzly is a tool for managing grafana dashboards, datasources, etc. with jsonnet
#

class grafana::grizzly (
    Stdlib::HTTPUrl  $grafana_url,
    Optional[String] $grafana_token = undef,
) {

    require_package('grizzly')

    file { '/etc/grafana/grizzly.env':
        owner     => grafana,
        group     => grafana,
        mode      => '0600',
        show_diff => false,
        content   => template('grafana/grizzly/grizzly.env.erb'),
    }

}
