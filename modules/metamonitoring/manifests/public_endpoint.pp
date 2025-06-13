# SPDX-License-Identifier: Apache-2.0
# @param config Configuration file to use, if the default is not suitable
class metamonitoring::public_endpoint (
    String        $prometheus_metamonitor_group,
    String        $install_dir,
    Stdlib::Host  $listen_address = '0.0.0.0',
    Stdlib::Port  $listen_port    = 20999,
    String        $user           = 'metamonpubep',
    Array[String] $datacenters    = 'dummy',
) {
    ensure_packages(['python3-gunicorn', 'python3-flask', 'python3-box'])

    user { $user:
        ensure     => 'present',
        shell      => '/usr/sbin/nologin',
        managehome => false,
        system     => true,
        groups     => $prometheus_metamonitor_group,
    }

    file {
        "${install_dir}/metamonitor_public_endpoint.py":
            ensure => file,
            source => 'puppet:///modules/metamonitoring/metamonitoring_public_endpoint.py',
            mode   => '0555',
            notify => Service['metamonitor_public_endpoint']
    }

    $dc_pattern = join($datacenters, '|')
    $re = Regexp("^.*\\.(${dc_pattern}).*$")
    $prometheus_instances = wmflib::puppetdb_query('resources [title, certname] { (((type ~ "^Profile::Prometheus::" or title ~ "^Profile::Prometheus") and tags = "profile::prometheus::instances") and (title != "Profile::Prometheus::Instances") and (title != "Profile::Prometheus::Ops_mysql")) }')
    # prometheus_isntances: used as a variable in env file template
    $monitored_instances = join(unique($prometheus_instances.reduce([]) |$memo, $instance| {
        if $instance['certname'] =~ $re {
            $site = $1
            $memo + "prometheus_${instance['title'].downcase.split(':')[-1]}_${site}"
        } else {
            # continue
            $memo
        }
    }.flatten() + ['thanos']), ',')

    file { '/etc/default/metamonitoring_public_endpoint':
        ensure  => file,
        content => template('metamonitoring/metamonitoring_public_endpoint.env.erb'),
        mode    => '0555',
        notify  => Service['metamonitor_public_endpoint']
    }

    systemd::service { 'metamonitor_public_endpoint':
        ensure  => present,
        content => init_template('metamonitoring_public_endpoint', 'systemd'),
        restart => true,
    }
}
