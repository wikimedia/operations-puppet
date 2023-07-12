# SPDX-License-Identifier: Apache-2.0
#
class profile::rsyslog::kubernetes (
    Boolean $enable                  = lookup('profile::rsyslog::kubernetes::enable', { 'default_value' => true }),
    String $kubernetes_cluster_name  = lookup('profile::kubernetes::cluster_name'),
) {
    include profile::rsyslog::shellbox

    $k8s_config = k8s::fetch_cluster_config($kubernetes_cluster_name)

    apt::package_from_component { 'rsyslog_kubernetes':
        component => 'component/rsyslog-k8s',
        packages  => ['rsyslog-kubernetes'],
    }

    $ensure = $enable ? {
      true    => present,
      default => absent,
    }

    $client_auth = profile::pki::get_cert($k8s_config['pki_intermediate_base'], 'rsyslog', {
        'ensure'          => $ensure,
        'renew_seconds'   => $k8s_config['pki_renew_seconds'],
        'names'           => [{ 'organisation' => 'view' }],
        'notify_services' => ['rsyslog'],
    })

    rsyslog::conf { 'kubernetes':
        ensure   => $ensure,
        content  => template('profile/rsyslog/kubernetes.conf.erb'),
        priority => 9,
    }
}
