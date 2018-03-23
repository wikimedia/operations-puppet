# profile class for labs monitoring specific stuff

class profile::labs::monitoring {
    $packages = [
        'python-keystoneauth1',
        'python-keystoneclient',
    ]

    package { $packages:
        ensure => 'present',
    }
}
