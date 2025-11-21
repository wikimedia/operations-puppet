# SPDX-License-Identifier: Apache-2.0
# new zuul (T405118) - scheduler
class profile::zuul::scheduler(
    String $image_version = lookup('profile::zuul::scheduler::image_version'),
    Wmflib::Ensure $service_ensure = lookup('profile::zuul::scheduler::service_ensure'),
){

    $host_ip = $facts['networking']['ip']

    systemd::service { 'zuul-scheduler':
        ensure    => $service_ensure,
        content   => systemd_template('zuul-scheduler'),
        require   => File['/etc/zuul/zuul.conf'],
        subscribe => File['/etc/zuul/zuul.conf'],
    }
}
