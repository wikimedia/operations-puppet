# SPDX-License-Identifier: Apache-2.0
#
class profile::rsyslog::kubernetes (
    Boolean $enable = lookup('profile::rsyslog::kubernetes::enable', { 'default_value' => false }),
    Cfssl::Ca_name $pki_intermediate = lookup('profile::kubernetes::pki::intermediate'),
    Integer[1800] $pki_renew_seconds = lookup('profile::kubernetes::pki::renew_seconds', { default_value => 952200 }),
    Optional[Stdlib::HTTPSUrl] $kubernetes_url = lookup('profile::rsyslog::kubernetes::kubernetes_url', { 'default_value' => undef }),
) {
    include profile::rsyslog::shellbox

    apt::package_from_component { 'rsyslog_kubernetes':
        component => 'component/rsyslog-k8s',
        packages  => ['rsyslog-kubernetes'],
    }

    $ensure = $enable ? {
      true    => present,
      default => absent,
    }

    $client_auth = profile::pki::get_cert($pki_intermediate, 'rsyslog', {
        'ensure'         => $ensure,
        'renew_seconds'  => $pki_renew_seconds,
        'names'          => [{ 'organisation' => 'view' }],
        'notify_service' => 'rsyslog'
    })

    rsyslog::conf { 'kubernetes':
        ensure   => $ensure,
        content  => template('profile/rsyslog/kubernetes.conf.erb'),
        priority => 9,
    }
}
