# Impala role classes.
#
# NOTE: Be sure that $cdh::impala::master_host is set in hiera!
# In production this is set in hieradata/eqiad/cdh/impala.yaml.


# == Class role::analytics::impala
# Installs base impala packages and the impala-shell client.
#
class role::analytics::impala {
    include cdh::impala
}

# == Class role::analytics::impala::worker
# Installs and configures the impalad server.
#
class role::analytics::impala::worker {
    include cdh::impala::worker
}

# == Class role::analytics::impala::master
# Installs and configures llama, impala-state-store and impala-catalog
#
class role::analytics::impala::master {
    include cdh::impala::master
}
