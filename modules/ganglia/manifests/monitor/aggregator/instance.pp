# an instance of a ganglia monitor aggregator service
define ganglia::monitor::aggregator::instance($monitored_site) {

    # not needed anymore and breaks on systemd
    if $::initsystem == 'upstart' {
        Ganglia::Monitor::Aggregator::Instance[$title] ->
        Service['ganglia-monitor-aggregator']
    }

    include ::ganglia::configuration
    include ::network::constants

    $aggregator = true

    $cluster = regsubst($title, '^(.*)_[^_]+$', '\1')
    if has_key($ganglia::configuration::clusters[$cluster], 'sites') {
        $sites = keys($ganglia::configuration::clusters[$cluster]['sites'])
    } else {
        $sites = $ganglia::configuration::default_sites
    }
    $id = $ganglia::configuration::clusters[$cluster]['id'] + $ganglia::configuration::id_prefix[$monitored_site]
    $desc = $ganglia::configuration::clusters[$cluster]['description']
    $desc_safe = regsubst($desc, '/', '_', 'G')
    $gmond_port = $ganglia::configuration::base_port + $id
    $cname = "${desc_safe} ${::site}"

    # Run these instances in the foreground
    $daemonize = 'no'

    # with systemd each aggregator instance is a separate service
    $aggsvcname = $::initsystem ? {
        'upstart' => 'ganglia-monitor-aggregator',
        'systemd' => "ganglia-monitor-aggregator@${id}.service",
        default   => 'ganglia-monitor-aggregator',
    }

    # on systemd each instance is a separate service
    # which is spawned from a common service template
    # and we only want to run it and create the config
    # if the site is a monitored site
    if $monitored_site in $sites {

        file { "/etc/ganglia/aggregators/${id}.conf":
            ensure  => 'present',
            require => File['/etc/ganglia/aggregators'],
            mode    => '0444',
            content => template("${module_name}/gmond.conf.erb"),
            notify  => Service[$aggsvcname],
        }
        # The following 2 rules are limited on purpose to only allow production
        # networks to reach the ganglia aggregators. ganglia has been tried in labs
        # and failed so for now we will be limiting ganglia aggregation to just
        # production
        ferm::service { "aggregator-udp-${id}":
            proto  => 'udp',
            port   => $gmond_port,
            srange => '$PRODUCTION_NETWORKS',
        }
        ferm::service { "aggregator-tcp-${id}":
            proto  => 'udp',
            port   => $gmond_port,
            srange => '$PRODUCTION_NETWORKS',
        }

        if $::initsystem == 'systemd' {
            service { "ganglia-monitor-aggregator@${id}.service":
                ensure   => running,
                provider => systemd,
                enable   => true,
            }
        }
    }
}
