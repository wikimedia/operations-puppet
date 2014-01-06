# vim: set ts=4 et sw=4:
# role/ocg_collection.pp
# offline content generator for the mediawiki collection extension

# Virtual resources for the monitoring server
@monitor_group { 'ocg_eqiad': description => 'offline content generator eqiad' }

class role::ocg_collection {
    system::role { 'ocg_collection': description => 'offline content generator for mediawiki collection extension' }

    include ocg_collection::service,
        passwords::redis

    class { 'ocg_collection':
        redis_host      => 'rdb1002.eqiad.wmnet',
        redis_password  => $passwords::redis::main_password,
        temp_dir        => '/a/ocg_collection',
    }
}

class role::ocg_collection::test {
    system::role { 'ocg-test': description => 'offline content generator for mediawiki collection extension (testing)' }

    include ocg_collection::service,
        passwords::redis

    class { 'ocg_collection':
        redis_host      => 'localhost',
        redis_password  => $passwords::redis::ocg_test_password,
        temp_dir        => '/a/ocg_collection',
    }

    class { 'redis':
        maxmemory       => '500Mb',
        password        => $passwords::redis::ocg_test_password,
    }
}
