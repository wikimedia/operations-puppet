# SPDX-License-Identifier: Apache-2.0
# @summary profile to install the puppetdb component of pcc
# @param ssldir loation of the ssldir
# @param master fqdn of the puppetmaster
# @param max_content_length maximum upload size for facts files
# @param output_dir the directory to find report files
class profile::puppet_compiler::puppetdb (
    Stdlib::Unixpath $ssldir             = lookup('profile::puppet_compiler::puppetdb::ssldir'),
    Stdlib::Fqdn     $master             = lookup('profile::puppet_compiler::puppetdb::master'),
    Integer          $max_content_length = lookup('profile::puppet_compiler::puppetdb::max_content_length'),
    Stdlib::Unixpath $output_dir         = lookup('profile::puppet_compiler::puppetdb::output_dir'),
) {
    include profile::puppet_compiler  # lint:ignore:wmf_styleguide

    # copy the catalog-differ puppet CA to validate connections to puppetdb
    file { '/etc/puppetdb/ssl/ca.pem':
        source => "${ssldir}/certs/ca.pem",
        owner  => 'puppetdb',
        before => Service['puppetdb'],
    }
    class {'profile::puppetdb':
        ca_path => '/etc/puppetdb/ssl/ca.pem',
        ssldir  => $ssldir,
        master  => $master,
    }
    class {'profile::puppetdb::database':
        ssldir => $ssldir,
        master => $master,
    }

    class {'puppet_compiler::uploader':
        max_content_length => $max_content_length,
    }
    class { 'profile::puppet_compiler::clean_reports':
        output_dir => $output_dir,
    }
    ferm::service {'puppet_compiler_web':
        proto  => 'tcp',
        port   => 'http',
        prio   => '30',
        # TODO: could restrict this to just the web proxy
        srange => '$LABS_NETWORKS',
    }
    nginx::site {'puppet-compiler':
        content => template('profile/puppet_compiler/nginx_site.erb'),
    }
    file_line { 'modify_nginx_magic_types':
        path    => '/etc/nginx/mime.types',
        line    => "    text/plain                            txt pson err diff gz;",
        match   => '\s+text/plain\s+txt',
        require => Nginx::Site['puppet-compiler'],
        notify  => Service['nginx'],
    }
}
