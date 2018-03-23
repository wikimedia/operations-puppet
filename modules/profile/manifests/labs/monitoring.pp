# profile class for labs monitoring specific stuff

class profile::labs::monitoring {

    include ::apache::mod::rewrite

    $packages = [
        'python-keystoneauth1',
        'python-keystoneclient',
        'python-novaclient',
    ]

    package { $packages:
        ensure => 'present',
    }
}
