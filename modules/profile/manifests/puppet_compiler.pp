class profile::puppet_compiler(
    $puppetdb_major_version = hiera('puppetdb_major_version', undef),
) {

    case $::realm {
        'labs'      : {
            # lint:ignore:wmf_styleguide
            require role::ci::slave::labs::common
            # lint:endignore

            ferm::service {'puppet_compiler_web':
                ensure => 'present',
                proto  => 'tcp',
                port   => 'http',
                prio   => '30',
                srange => '$LABS_NETWORKS'
            }
        }
        default     : { fail("Realm ${::realm} NOT supported by this role.") }
    }

    class { '::puppet_compiler':
        puppetdb_major_version => $puppetdb_major_version,
    }

    if $puppetdb_major_version == 4 {
        include ::profile::puppet_compiler::postgres_database
    }

    # Conftool + etcd are needed for the conftool function to work
    # do not bother with hiera here, for now.
    class { '::profile::conftool::client':
        srv_domain => '',
        host       => '127.0.0.1',
        port       => 2379,
        namespace  => dirname('/conftool/v1'),
        protocol   => 'http',
    }

}
