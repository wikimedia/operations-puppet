# SPDX-License-Identifier: Apache-2.0
class metamonitoring::icinga_external_monitoring (
    Wmflib::Ensure $ensure,
    String $user,
    Stdlib::Absolutepath $status_dir,
    Metamonitoring::Vhost_basic_auth $vhost_basic_auth,
    Metamonitoring::Smtp_auth $smtp_auth,
) {
    ensure_packages(['python3-dnspython', 'python3-requests', 'python3-yaml'])

    $git_clone_ensure = $ensure == 'present' ? {
        true  => 'latest',
        false => 'absent',
    }

    git::clone { 'operations/software/external-monitoring':
        ensure    => $git_clone_ensure,
        directory => '/srv/external-monitoring',
        branch    => 'master',
    }

    $check_icinga_ensure = $ensure == 'present' ? {
        true  => 'link',
        false => 'absent',
    }

    file { '/usr/local/bin/check_icinga':
        ensure  => $check_icinga_ensure,
        target  => '/srv/external-monitoring/icinga/check_icinga.py',
        require => Git::Clone['operations/software/external-monitoring'],
    }

    # status dir
    file { "${status_dir}/icinga_external_monitoring":
        ensure  => stdlib::ensure($ensure, 'directory'),
        owner   => $user,
        group   => $user,
        mode    => '0755',
        require => User[$user],
    }

    # config dir
    file { '/etc/check_icinga':
        ensure => stdlib::ensure($ensure, 'directory'),
        group  => $user,
        mode   => '0750',
    }

    file { '/etc/check_icinga/config.yaml':
        ensure  => stdlib::ensure($ensure, 'file'),
        require => File['/etc/check_icinga'],
        group   => $user,
        mode    => '0640',
        content => epp('metamonitoring/icinga_external_monitoring_config.yaml.epp', {
            'vhost_basic_auth' => $vhost_basic_auth,
            'smtp_auth'        => $smtp_auth,
        })
    }

    exec { '/etc/check_icinga/contacts.yaml.last':
        command => 'generate-check-icinga-contacts > /etc/check_icinga/contacts.yaml.last',
        path    => ['/usr/bin', '/bin', '/usr/local/bin'],
        unless  => "bash -c '/usr/local/bin/generate-check-icinga-contacts | /usr/bin/diff -q - /etc/check_icinga/contacts.yaml'",
        group   => $user,
        umask   => '026',
    }

    exec { '/etc/check_icinga/contacts.yaml':
        command => 'mv /etc/check_icinga/contacts.yaml.last /etc/check_icinga/contacts.yaml',
        path    => ['/usr/bin', '/bin', '/usr/local/bin'],
        onlyif  => '/srv/external-monitoring/icinga/check_icinga_validate_config.py --contacts /etc/check_icinga/contacts.yaml.last',
        require => Exec['/etc/check_icinga/contacts.yaml.last'],
        group   => $user,
        umask   => '026',
    }

    $icinga_instances = wmflib::puppetdb_query('resources [certname] { (title = "icinga") and (type = "Systemd::Service")}')
    $icinga_instances.each |$_instance_fqdn| {
        $instance_fqdn = $_instance_fqdn['certname']
        $instance = regsubst($instance_fqdn, '\..*$', '')

        $command = "/usr/local/bin/check_icinga --tries 3 --sleep 10 --state-dir ${status_dir}/icinga_external_monitoring -c /etc/check_icinga/config.yaml --suppress-notifications --suppress-pages ${instance_fqdn}"
        systemd::timer::job { "check_icinga-${instance}":
            ensure        => $ensure,
            description   => "Icinga external-monitoring: cache updater for instance ${instance}.",
            user          => $user,
            group         => $user,
            ignore_errors => false,
            command       => $command,
            interval      => [ { 'start' => 'OnUnitInactiveSec', 'interval' => '2min' }, ],
        }
    }
}
