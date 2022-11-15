# SPDX-License-Identifier: Apache-2.0
# @summary profiletp configure the compiler nodes
# @param output_dir the directory to find report files
# @param web_frontend if true configure the web front end
# @param puppetdb_host puppetdb host
# @param puppetdb_port puppetdb port
class profile::puppet_compiler (
    Stdlib::Unixpath       $output_dir     = lookup('profile::puppet_compiler::output_dir'),
    Boolean                $web_frontend   = lookup('profile::puppet_compiler::web_fronend'),
    Optional[Stdlib::Host] $puppetdb_host  = lookup('profile::puppet_compiler::puppetdb_host'),
    Optional[Stdlib::Port] $puppetdb_port  = lookup('profile::puppet_compiler::puppetdb_port'),
) {
    requires_realm('labs')

    include profile::openstack::base::puppetmaster::enc_client
    class {'puppet_compiler': }
    class { 'puppetmaster::puppetdb::client':
        hosts => [$facts['networking']['fqdn']],
    }
    # puppetdb configuration
    file { "${puppet_compiler::vardir}/puppetdb.conf":
        source => '/etc/puppet/puppetdb.conf',
        owner  => $puppet_compiler::user,
    }
    nginx::site {'puppet-compiler':
        ensure  => $web_frontend.bool2str('present', 'absent'),
        content => template('profile/puppet_compiler/nginx_site.erb'),
    }
    if $web_frontend {
        ferm::service {'puppet_compiler_web':
            proto  => 'tcp',
            port   => 'http',
            prio   => '30',
            # TODO: could restrict this to just the db1001 and localhost
            srange => '$LABS_NETWORKS',
        }
        file_line { 'modify_nginx_magic_types':
            path    => '/etc/nginx/mime.types',
            line    => "    text/plain                            txt pson err diff gz;",
            match   => '\s+text/plain\s+txt',
            require => Nginx::Site['puppet-compiler'],
            notify  => Service['nginx'],
        }
    }
}
