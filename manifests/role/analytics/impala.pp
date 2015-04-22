# Impala role classes.
#
# NOTE: Be sure that $analytics::impala::master_host is set in hiera!
# In production this is set in hieradata/eqiad/analytics/impala.yaml.

# == Class role::analytics::impala
# Installs base impala packages and the impala-shell client.
#
class role::analytics::impala {
    class { cdh::impala:
        master_host => hiera('analytics::impala::master_host')
    }
}

# == Class role::analytics::impala::worker
# Installs and configures the impalad server.
#
class role::analytics::impala::worker {
    include role::analytics::impala
    include cdh::impala::worker
}

# == Class role::analytics::impala::master
# Installs and configures llama, impala-state-store and impala-catalog
#
class role::analytics::impala::master {
    include role::analytics::impala
    include cdh::impala::master
}
