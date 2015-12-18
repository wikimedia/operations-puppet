class role::labs::ores::precached {
    include ::ores::precached
}

class role::labs::ores::web {
    include ::ores::web
    include ::ores::redisproxy
}

class role::labs::ores::flower {
    include ::ores::flower
    include ::ores::redisproxy
}

class role::labs::ores::worker {
    include ::ores::worker
    include ::ores::redisproxy
}

class role::labs::ores::redis {
    class { '::ores::redis':
        queue_maxmemory => '512M',
        cache_maxmemory => '3G',
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
        cache       => false,
        require     => Labs_lvm::Volume['srv'],
    }
}

class role::labs::ores::staging {
    class { 'ores::base':
        branch => 'master',
    }

    include ::ores::web
    include ::ores::worker
    include ::ores::flower

    class { '::ores::lb':
        realservers => [ 'localhost:8080' ],
        cache       => false,
    }

    class { '::ores::redis':
        cache_maxmemory => '512M',
        queue_maxmemory => '256M',
    }

    class { '::ores::redisproxy':
        server => 'localhost',
    }
}
