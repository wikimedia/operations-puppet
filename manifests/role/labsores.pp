class role::labs::ores::web {
    inlcude ::ores::base
    include ::ores::web

    class { '::ores::redisproxy':
        server => hiera('redis_server'),
    }
}

class role::labs::ores::worker {
    inlcude ::ores::base
    include ::ores::worker

    class { '::ores::redisproxy':
        server => hiera('redis_server'),
    }
}

class role::labs::ores::redis {
    class { '::ores::redis':
        maxmemory => '3G',
    }
}

class role::labs::ores::lb(
    $realservers,
) {
    labs_lvm::volume { 'srv':
        mountat => '/srv',
    }

    class { '::ores::lb':
        realservers => $realservers,
        cache       => true,
        require     => Labs_lvm::Volume['srv'],
    }
}

class role::labs::ores::staging {
    class { 'ores::base':
        branch => 'master',
    }

    include ::ores::web
    include ::ores::worker

    class { '::ores::lb':
        realservers => [ 'localhost:8080' ],
        cache       => false,
    }

    class { '::ores::redis':
        maxmemory => '256M',
    }

    class { '::ores::redisproxy':
        server => 'localhost',
    }
}
