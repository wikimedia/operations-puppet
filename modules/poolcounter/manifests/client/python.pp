# Installs the base configuration file for running poolcounter-enabled
# python applications, and the corresponding client
class poolcounter::client::python(
    Wmflib::Ensure $ensure,
    Poolcounter::Backends $backends
) {
    if $ensure == 'present' {
        # python3-poolcounter uses typing which is not available in python3.4 (jessie)
        debian::codename::require::min('stretch')
    }
    package { 'python3-poolcounter':
        ensure => $ensure,
    }

    class { 'poolcounter::client':
        ensure   => $ensure,
        backends => $backends,
    }
}
