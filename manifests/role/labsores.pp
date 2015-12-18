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

    ores::config::staging { 'staging':
        settings => {
            'score_caches'     => {
                'ores_redis' => {
                    'host' => '127.0.0.1',
                    'port' => '6380',
                }
            },
            'score_processors' => {
                'ores_celery' => {
                    'BROKER_URL'            => 'redis://127.0.0.1:6379',
                    'CELERY_RESULT_BACKEND' => 'redis://127.0.0.1:6379',
                }
            }
        },
        priority => '99',
    }
}
