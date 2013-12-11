# vim: set ts=4 et sw=4:
# role/ocg.pp
# offline content generator for the mediawiki collection extension

# Virtual resources for the monitoring server
@monitor_group { 'ocg_eqiad': description => 'offline content generator eqiad' }

class role::ocg {
    system::role { 'ocg': description => 'offline content generator for mediawiki collection extension' }

    include ocg,
        passwords::redis

    class { 'ocg':
        redis_host      => 'rdb1002.eqiad.wmnet',
        redis_password  => $passwords::redis::main_password,
        temp_dir        => '/a/ocg/',
    }
}

class role::ocg::test {
    system::role { 'ocg-test': description => 'offline content generator for mediawiki collection extension (testing)' }

    include ocg,
        passwords::redis

    class { 'ocg':
        redis_host      => 'localhost',
        redis_password  => $passwords::redis::ocg_test_password,
        temp_dir        => '/a/ocg',
    }

    class { 'redis':
        maxmemory       => '500Mb',
        password        => $passwords::redis::ocg_test_password,
    }
}
