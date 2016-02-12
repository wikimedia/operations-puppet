# == Class role::analytics::impala
# Installs base impala packages and the impala-shell client.
#
class role::analytics::impala {
    class { 'cdh::impala':
        master_host => hiera('analytics::impala::master_host')
    }
}
