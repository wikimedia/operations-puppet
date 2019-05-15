define trafficserver::layout(
    Trafficserver::Paths $paths,
) {
    if !defined(File[$paths['base_path']]) {
        file { $paths['base_path']:
            ensure => directory,
            owner  => $trafficserver::user,
            mode   => '0755',
        }
    }

    file { "/etc/trafficserver/${title}-layout.yaml":
        ensure  => file,
        owner   => $trafficserver::user,
        mode    => '0400',
        content => template('trafficserver/layout.yaml.erb'),
        require => Package['trafficserver'],
    }

    exec { "bootstrap-${title}-ats-runroot":
        command => "/usr/bin/traffic_layout init --path ${paths['prefix']} --layout /etc/trafficserver/${title}-layout.yaml -a --copy-style=soft",
        creates => "${paths['prefix']}/runroot.yaml",
        require => File["/etc/trafficserver/${title}-layout.yaml"],
    }
}
