# SPDX-License-Identifier: Apache-2.0
# Install the gVisor container runtime for Docker.
class profile::docker::gvisor(
    Wmflib::Ensure $ensure = lookup('docker::gvisor::ensure', { default_value => 'present' }),
) {
    apt::repository { 'gvisor':
        ensure     =>  $ensure,
        uri        => 'http://apt.wikimedia.org/wikimedia',
        dist       => "${::lsbdistcodename}-wikimedia",
        components => 'thirdparty/gvisor',
    }

    package { 'runsc':
        ensure  =>  $ensure,
        require => Apt::Repository['gvisor'],
    }

    systemd::override { 'docker-runsc-runtime':
        ensure  => $ensure,
        unit    => 'docker.service',
        content => "[Service]\nEnvironment=DOCKER_OPTS=--add-runtime=runsc=/usr/bin/runsc\n",
        restart => true,
        require => Package['runsc'],
    }
}
