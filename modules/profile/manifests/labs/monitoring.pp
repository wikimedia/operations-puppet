# profile class for labs monitoring specific stuff

class profile::labs::monitoring {
    $packages = [
        'python-keystoneauth1',
        'python-keystoneclient',
        'python-novaclient',
        'libapache2-mod-uwsgi',
    ]

    package { $packages:
        ensure => 'present',
    }
}
