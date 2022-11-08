# SPDX-License-Identifier: Apache-2.0
# @summary profile to install the puppetdb component of pcc
# @param ssldir loation of the ssldir
# @param master fqdn of the puppetmaster
# @param max_content_length maximum upload size for facts files
class profile::puppet_compiler::puppetdb (
    Stdlib::Unixpath $ssldir             = lookup('profile::puppet_compiler::puppetdb::ssldir'),
    Stdlib::Fqdn     $master             = lookup('profile::puppet_compiler::puppetdb::master'),
    Integer          $max_content_length = lookup('profile::puppet_compiler::puppetdb::max_content_length'),
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
}
