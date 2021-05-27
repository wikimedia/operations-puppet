# grizzly is a tool for managing grafana dashboards, datasources, etc. with jsonnet
#

class grafana::grizzly (
    Stdlib::HTTPUrl  $grafana_url,
    Optional[String] $grafana_token = undef,
) {

    require_package('grizzly')

    file { '/etc/grafana/grizzly.env':
        owner     => grafana,
        group     => ops,
        mode      => '0660',
        show_diff => false,
        content   => template('grafana/grizzly/grizzly.env.erb'),
    }

    # Clone the grafana-grizzly repository into a /srv/grafana-grizzly
    git::clone { 'operations/grafana-grizzly':
        ensure    => 'latest',
        directory => '/srv/grafana-grizzly',
        owner     => 'root',
        group     => 'ops',
        mode      => '0440',
    }

}
