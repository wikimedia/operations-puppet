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
