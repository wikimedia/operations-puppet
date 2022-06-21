# SPDX-License-Identifier: Apache-2.0
# grizzly is a tool for managing grafana dashboards, datasources, etc. with jsonnet
#

class grafana::grizzly (
    Stdlib::HTTPUrl  $grafana_url,
    Optional[String] $grafana_token = undef,
) {

    ensure_packages('grizzly')

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

    # /usr/local/bin/grr wrapper calls /usr/bin/grr with environment variables set
    file { '/usr/local/bin/grr':
        owner  => grafana,
        group  => ops,
        mode   => '0555',
        source => 'puppet:///modules/grafana/grr.sh',
    }

}
