# SPDX-License-Identifier: Apache-2.0
# Installs the NFS tracing script and run it with a systemd unit
class profile::wmcs::kubeadm::infra_tracing::nfs (
    String[1]        $username     = lookup('profile::wmcs::kubeadm::infra_tracing::nfs::username'),
    String[1]        $password     = lookup('profile::wmcs::kubeadm::infra_tracing::password'),
    Stdlib::HTTPSUrl $loki_url     = lookup('profile::wmcs::kubeadm::infra_tracing::loki_url', {default_value => 'https://localhost:30004/'}),
    Float[0.0]       $buffer_secs  = lookup('profile::wmcs::kubeadm::infra_tracing::buffer_secs', {default_value => 30.0}),
    Integer[1]       $buffer_lines = lookup('profile::wmcs::kubeadm::infra_tracing::buffer_lines', {default_value => 100}),
    String[1]        $log_level    = lookup('profile::wmcs::kubeadm::infra_tracing::log_level', {default_value => 'INFO'}),
    Wmflib::Ensure   $ensure       = lookup('profile::wmcs::kubeadm::infra_tracing::ensure', {default_value => 'absent'}),
) {
    ensure_packages([
        "linux-headers-${::kernelrelease}",
        'python3-bpfcc',
    ], {
        ensure  => $ensure,
    })

    $script_path = '/usr/local/sbin/infra-tracing-nfs'
    file { $script_path:
        ensure => stdlib::ensure($ensure, 'file'),
        source => 'puppet:///modules/profile/wmcs/kubeadm/infra_tracing/infra-tracing-nfs.py',
        mode   => '0544',
    }

    $ini_config = '/etc/infra-tracing-nfs.ini'
    file { $ini_config:
        ensure  => stdlib::ensure($ensure, 'file'),
        content => template('profile/wmcs/kubeadm/infra_tracing/infra-tracing-nfs.ini'),
        mode    => '0400',
        notify  => Service['infra-tracing-nfs'],
    }

    systemd::service { 'infra-tracing-nfs':
        ensure  => $ensure,
        content => template('profile/wmcs/kubeadm/infra_tracing/infra-tracing-nfs.systemd.erb'),
        restart => true,
    }
}
