# SPDX-License-Identifier: Apache-2.0
class profile::wmcs::metricsinfra::thanos_rule (
    Array[Stdlib::Fqdn] $alertmanager_hosts = lookup('profile::wmcs::metricsinfra::prometheus_alertmanager_hosts'),
    Array[Stdlib::Fqdn] $thanos_fe_hosts    = lookup('profile::wmcs::metricsinfra::thanos_fe_hosts'),
    Stdlib::Fqdn        $ext_fqdn           = lookup('profile::wmcs::metricsinfra::prometheus::ext_fqdn'),
) {
    $rule_hosts = Hash($thanos_fe_hosts.map |Stdlib::Fqdn $host| {
        $ret = [
            $host,
            {
                # convert fqdn to hostname
                'replica' => regsubst($host, '\..*', ''),
            },
        ]

        $ret
    })

    wmflib::dir::mkdir_p('/srv/alerts-thanos/', {
        mode   => '0770',
        owner  => 'prometheus',
        group  => 'prometheus',
    })

    class { 'thanos::rule':
        rule_hosts        => $rule_hosts,
        alertmanagers     => $alertmanager_hosts,
        use_objstore      => false,
        objstore_account  => undef,
        objstore_password => undef,
        rule_files        => ['/srv/alerts-thanos/*.yaml'],
        query_url         => "https://${ext_fqdn}",
    }

    profile::wmcs::metricsinfra::prometheus_configurator::output_config { 'thanos-rule':
        kind    => 'thanos_rule',
        options => {
            alert_file_path => '/srv/alerts-thanos/global.yaml',
            units_to_reload => [
                'thanos-rule.service',
            ]
        },
    }
}
