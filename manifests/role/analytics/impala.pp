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

    ferm::service { 'impalad':
        proto  => 'tcp',
        port   => '(21000 21050 22000 23000 25000 28000)',
        srange => '$ANALYTICS_NETWORKS',
    }
}

# == Class role::analytics::impala::master
# Installs and configures llama, impala-state-store and impala-catalog
#
class role::analytics::impala::master {
    include role::analytics::impala
    include base::firewall

    # The llama-master package stupidly creates the llama user
    # with a non system uid.  This causes our admin module to
    # attempt to remove the user.  Manage the user manually
    # here in puppet before installing that package.
    user { 'llama':
        ensure  => 'present',
        comment => 'Llama',
        home    => '/var/lib/llama',
        shell   => '/bin/bash',
        system  => true,
        before  => Class['cdh::impala::master'],
    }

    include cdh::impala::master

    ferm::service { 'impala-state-store':
        proto  => 'tcp',
        port   => '(24000 25010)',
        srange => '$ANALYTICS_NETWORKS',
    }
    ferm::service { 'impala-catalog':
        proto  => 'tcp',
        port   => '(23020 25020 26000)',
        srange => '$ANALYTICS_NETWORKS',
    }
    ferm::service { 'impala-llama':
        proto  => 'tcp',
        port   => '(15000 15001 15002)',
        srange => '$ANALYTICS_NETWORKS',
    }
}
