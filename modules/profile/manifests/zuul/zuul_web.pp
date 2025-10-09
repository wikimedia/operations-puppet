# SPDX-License-Identifier: Apache-2.0
# new zuul (T393873) - zuul-web (T405119)
class profile::zuul::zuul_web(
    String $image_version = lookup('profile::zuul::zuul_web::image_version'),
){

    $host_ip = $facts['networking']['ip']

    systemd::service { 'zuul-web':
        ensure    => 'present',
        content   => systemd_template('zuul-web'),
        require   => File['/etc/zuul/zuul.conf'],
        subscribe => File['/etc/zuul/zuul.conf'],
    }
}
