# @summary profiletp configure the compiler nodes
class profile::puppet_compiler(
    Boolean $enable_web = lookup('profile::puppet_compiler::enable_web'),
) {
    requires_realm('labs')

    include profile::openstack::base::puppetmaster::enc_client

    ferm::service {'puppet_compiler_web':
        ensure => $enable_web.bool2str('present', 'absent'),
        proto  => 'tcp',
        port   => 'http',
        prio   => '30',
        srange => '$LABS_NETWORKS'
    }
    class {'puppet_compiler':
        enable_web => $enable_web,
    }
}
