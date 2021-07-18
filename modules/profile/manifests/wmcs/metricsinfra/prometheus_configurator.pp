class profile::wmcs::metricsinfra::prometheus_configurator (
    Array[Stdlib::Fqdn] $alertmanager_hosts = lookup('profile::wmcs::metricsinfra::prometheus_alertmanager_hosts'),
    Array[Hash] $projects = lookup('profile::wmcs::metricsinfra::monitored_projects'),
    Array[Hash] $global_jobs = lookup('profile::wmcs::metricsinfra::global_jobs'),
    Array[Hash] $global_alert_groups = lookup('profile::wmcs::metricsinfra::global_alert_groups'),
) {
    ensure_packages(['python3-requests', 'python3-yaml'])

    $gitdir = '/var/lib/git'
    $clone_dir = "${gitdir}/cloud/metricsinfra/prometheus-configurator"
    wmflib::dir::mkdir_p("${gitdir}/cloud/metricsinfra")

    group { 'prometheus-configurator':
        ensure => present,
        system => true,
    }

    user { 'prometheus-configurator':
        ensure => present,
        system => true,
        gid    => 'prometheus-configurator',
        home   => '/nonexistent',
        # add to prometheus group for access to edit its configuration
        groups => ['prometheus'],
    }

    # TODO: better deployment model (scap, debian, so on)
    git::clone { 'cloud/metricsinfra/prometheus-configurator':
        ensure    => latest,
        directory => $clone_dir,
        owner     => 'prometheus-configurator',
        group     => 'prometheus-configurator',
        require   => User['prometheus-configurator'],
        notify    => Exec['prometheus-configurator'],
    }

    file { '/etc/prometheus-configurator':
        ensure => directory,
        owner  => 'prometheus-configurator',
        group  => 'prometheus-configurator',
    }

    $project_configs = $projects.reduce ({}) |Hash $agg, Hash $project| {
        $jobs = has_key($project, 'jobs') ? {
            true  => $project['jobs'],
            false => [],
        }
        $alerts = has_key($project, 'alerts') ? {
            true  => $project['alerts'],
            false => [],
        }

        $notify_email = has_key($project, 'notify_email') ? {
            true  => $project['notify_email'],
            false => [],
        }

        $agg.merge({
            $project['name'] => {
                jobs         => $jobs,
                alerts       => $alerts,
                notify_email => $notify_email,
            },
        })
    }

    $config = {
        openstack => {
            credentials => '/etc/novaobserver.yaml',
        },
        alertmanager_hosts => $alertmanager_hosts.map |Stdlib::Fqdn $host| {
            "${host}:9093"
        },
        global_jobs => $global_jobs,
        global_alert_groups => $global_alert_groups,
        projects => $project_configs,
        outputs => [],
        external_rules_files => [
            'alerts_default.yml',
        ],
    }

    file { '/etc/prometheus-configurator/config.yaml':
        ensure  => present,
        owner   => 'prometheus-configurator',
        group   => 'prometheus-configurator',
        content => ordered_yaml($config),
        mode    => '0440',
        notify  => Exec['prometheus-configurator'],
    }

    file { '/etc/prometheus-configurator/config.d/':
        ensure => directory,
        owner  => 'prometheus-configurator',
        group  => 'prometheus-configurator',
    }

    exec { 'prometheus-configurator':
        command     => '/usr/bin/python3 scripts/create-prometheus-config --config /etc/prometheus-configurator/config.yaml --config "/etc/prometheus-configurator/config.d/*.yaml"',
        cwd         => $clone_dir,
        environment => [
            "PYTHONPATH=${clone_dir}"
        ],
        user        => 'prometheus-configurator',
        group       => 'prometheus-configurator',
        require     => [
            File['/etc/prometheus-configurator/config.yaml'],
            Git::Clone['cloud/metricsinfra/prometheus-configurator'],
        ],
        refreshonly => true,
    }
}
