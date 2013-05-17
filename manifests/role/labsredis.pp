# See https://gerrit.wikimedia.org/r/#/c/54970/ and https://projects.puppetlabs.com/issues/2053
# before renaming.
class role::labs-redis {
        require passwords::redis

        class { "::redis":
                dir                       => "/var/lib/redis/",
                maxmemory                 => "500mb",
                persist                   => "aof",
                redis_replication         => undef,
                password                  => $::passwords::redis::main_password,
                auto_aof_rewrite_min_size => "64mb",
        }
}
