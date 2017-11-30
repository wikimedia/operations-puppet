# == Class cergen
# Installs cergen package.
class cergen {
    # If Jessie, we need to manually specify versions of some dependencies from backports.
    if os_version('debian jessie') {
        if !defined(Package['python3-pyasn1']) {
            package { 'python3-pyasn1':
                ensure => '0.1.9-1~bpo8+1',
            }
        }
        if !defined(Package['python3-setuptools']) {
            package { 'python3-setuptools':
                ensure => '33.1.1-1~bpo8+1',
            }
        }
        if !defined(Package['python3-cryptography']) {
            package { 'python3-cryptography':
                ensure  => '1.7.1-3~bpo8+1',
                require => [
                    Package['python3-pyasn1'],
                    Package['python3-setuptools']
                ],
            }
        }
        if !defined(Package['python3-openssl']) {
            package { 'python3-openssl':
                ensure  => '16.0.0-1~bpo8+1',
                require => Package['python3-cryptography'],
                before  => Package['cergen'],
            }
        }
    }

    # Not using require_package since it fails the whole
    # class if the above dependencies are not first installed.
    package { 'cergen':
        ensure => 'present',
    }
}
