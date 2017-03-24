# filtertags: labs-project-toolsbeta labs-project-puppet3-diffs
class role::puppet_compiler {

    system::role { 'role::puppet_compiler': description => 'Puppet compiler jenkins slave'}

    case $::realm {
        'labs'      : {
            require role::ci::slave::labs::common
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

    include ::puppet_compiler

    # Conftool + etcd are needed for the conftool function to work
    # do not bother with hiera here, for now.
    class { '::profile::conftool::client':
        srv_domain => undef,
        host       => '127.0.0.1',
        port       => 2379,
        namespace  => '/conftool/v1',
    }
}
