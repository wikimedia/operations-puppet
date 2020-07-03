# Add tools to build envoy
# filtertags: packaging
class profile::envoy::builder {
    # this class assumes you have an unused volume group and you want to use it for building envoy.
    # we need an lvm volume for docker images used during the build
    labs_lvm::volume { 'docker':
        size      => '10%FREE',
        mountat   => '/var/lib/docker',
        mountmode => '711'
    }
    # we need a very large /tmp because the envoy build dumps more than 100 GB of
    # waste into it.
    labs_lvm::volume { 'tmp':
        size      => '50%FREE',
        mountat   => '/tmp',
        mountmode => '777',
    }
    # We need some space to use pbuilder with.
    labs_lvm::volume { 'pbuilder':
        size    => '20%FREE',
        mountat => '/var/cache/pbuilder'
    }
    # Where the source code for envoy is going to be, and also the produced artifacts.
    labs_lvm::volume { 'sources':
        mountat => '/usr/src',
    }
    # Now let's ensure envoy sources are checked out
    git::clone { 'envoyproxy':
        origin    => 'https://github.com/envoyproxy/envoy.git',
        directory => '/usr/src/envoyproxy',
        require   => Labs_lvm::Volume['sources']
    }

    # Install an ugly script that automates building envoy.
    file { '/usr/local/bin/build-envoy-deb':
        source => 'puppet:///modules/profile/envoy/build_envoy_deb.sh'
    }
}
