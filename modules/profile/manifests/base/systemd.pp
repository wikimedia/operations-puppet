# SPDX-License-Identifier: Apache-2.0
class profile::base::systemd(
    Stdlib::Yes_no $systemd_cpu_accounting = lookup('profile::base::systemd::cpu_accounting'),
    Stdlib::Yes_no $systemd_blockio_accounting = lookup('profile::base::systemd::blockio_accounting'),
    Stdlib::Yes_no $systemd_memory_accounting = lookup('profile::base::systemd::memory_accounting'),
    Stdlib::Yes_no $systemd_ip_accounting = lookup('profile::base::systemd::ip_accounting'),
) {
    debian::codename::require::min('buster')

    class { '::systemd::config':
        cpu_accounting     => $systemd_cpu_accounting,
        blockio_accounting => $systemd_blockio_accounting,
        memory_accounting  => $systemd_memory_accounting,
        ip_accounting      => $systemd_ip_accounting,
    }
}
