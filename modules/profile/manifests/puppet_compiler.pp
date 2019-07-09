class profile::puppet_compiler(
    $cloud_puppetmaster = hiera('profile::puppet_compiler::cloud_puppetmaster')
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

            # delete output files older than a month (T222072)
            $output_dir = '/srv/jenkins-workspace/puppet-compiler/output'
            cron { 'delete-old-output-files':
                ensure   => 'present',
                command  => "find ${output_dir} -ctime +31 -delete",
                user     => 'root',
                monthday => '1',
                hour     => '1',
                minute   => '30',
            }
        }
        default     : { fail("Realm ${::realm} NOT supported by this role.") }
    }

    include ::puppet_compiler
    include ::profile::puppet_compiler::postgres_database

    # Conftool + etcd are needed for the conftool function to work
    # do not bother with hiera here, for now.
    class { '::profile::conftool::client':
        srv_domain => '',
        host       => '127.0.0.1',
        port       => 2379,
        namespace  => dirname('/conftool/v1'),
        protocol   => 'http',
    }

    class {'::openstack::puppet::master::enc':
        puppetmaster => $cloud_puppetmaster,
    }
}
