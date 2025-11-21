# SPDX-License-Identifier: Apache-2.0
# new zuul (T393873) - zuul-web (T405119)
class profile::zuul::zuul_web(
    String $image_version = lookup('profile::zuul::zuul_web::image_version'),
    Wmflib::Ensure $service_ensure = lookup('profile::zuul::zuul_web::service_ensure'),
){

    $host_ip = $facts['networking']['ip']

    firewall::service { 'zuul-web-docker-httpd':
        proto  => 'tcp',
        port   => 80,
        srange => '172.17.0.0/16',
    }

    systemd::service { 'zuul-web':
        ensure    => $service_ensure,
        content   => systemd_template('zuul-web'),
        require   => File['/etc/zuul/zuul.conf'],
        subscribe => File['/etc/zuul/zuul.conf'],
    }
}
