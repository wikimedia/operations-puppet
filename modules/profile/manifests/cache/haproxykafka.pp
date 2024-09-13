# SPDX-License-Identifier: Apache-2.0
class profile::cache::haproxykafka(
    Wmflib::Ensure $ensure = lookup('profile::cache::haproxykafka::ensure', {'default_value' => absent})
) {

    class { 'haproxykafka':
        ensure => $ensure
    }
}
