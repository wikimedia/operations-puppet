# SPDX-License-Identifier: Apache-2.0
# == Class: benthos
#
# Installs base package and configs for Benthos
#
class benthos(
    Wmflib::Ensure $ensure = present,
) {

    package { 'benthos':
        ensure => $ensure,
    }

    file { '/etc/benthos':
        ensure => stdlib::ensure($ensure, 'directory'),
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
}
