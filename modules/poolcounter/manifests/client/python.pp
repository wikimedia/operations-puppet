# SPDX-License-Identifier: Apache-2.0
# Installs the base configuration file for running poolcounter-enabled
# python applications, and the corresponding client
class poolcounter::client::python(
    Wmflib::Ensure $ensure,
    Poolcounter::Backends $backends
) {
    package { 'python3-poolcounter':
        ensure => $ensure,
    }

    class { 'poolcounter::client':
        ensure   => $ensure,
        backends => $backends,
    }
}
