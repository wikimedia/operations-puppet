# SPDX-License-Identifier: Apache-2.0
# Self-hosted puppetserver for a Pontoon stack

class profile::puppetserver::pontoon (
    Stdlib::Unixpath               $git_basedir  = lookup('profile::puppetserver::git::basedir'),
    Stdlib::Unixpath               $code_dir     = lookup('profile::puppetserver::code_dir'),
    Boolean                        $pki_enabled  = lookup('profile::puppetserver::pontoon::pki_enabled', {'default_value' => false}),
    Boolean                        $zk_enabled   = lookup('profile::puppetserver::pontoon::zk_enabled', {'default_value' => false}),
    Hash[String, Stdlib::Unixpath] $extra_mounts = lookup('profile::puppetserver::extra_mounts'),
) {
    class { 'pontoon::enc': }

    file { ['/etc/pontoon', '/var/lib/pontoon']:
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    file { '/etc/pontoon/hiera':
        ensure => directory,
        owner  => 'puppet',
        group  => 'puppet',
        mode   => '0755',
    }

    # XXX refactor to use profile::puppetserver::git instead
    ['operations/puppet', 'labs/private'].each |$repo| {
        wmflib::dir::mkdir_p("${git_basedir}/${repo}", {
            owner  => 'puppet',
            group  => 'puppet',
        })

        # Cloning from bootstrap repos takes precedence over gerrit
        $origin = find_file("/tmp/bootstrap/git/${$repo.basename}/.git/config") ? {
            undef   => undef,
            default => "/tmp/bootstrap/git/${$repo.basename}",
        }

        git::clone { $repo:
            directory => "${git_basedir}/${repo}",
            owner     => 'puppet',
            mode      => '0755',
            origin    => $origin,
        }
    }

    file { "${code_dir}/environments/production":
        ensure  => link,
        target  => "${git_basedir}/operations/puppet",
        require => File["${code_dir}/environments"],
    }

    file { '/etc/puppet/private':
        ensure => link,
        target => "${git_basedir}/labs/private",
    }

    $puppetdb_hosts = pontoon::hosts_for_role('puppetdb')
    $puppetdb_ok_file='/var/lib/pontoon/puppetdb-ok'

    file { '/usr/local/bin/probe-puppetdb':
        ensure => present,
        source => 'puppet:///modules/pontoon/bootstrap/probe-puppetdb.sh',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    if $puppetdb_hosts == undef {
        # Do not enable puppetdb
        $puppetdb_urls = []

        file { $puppetdb_ok_file:
            ensure => absent,
        }
    } else {
        # Wait for puppetdb to be ready before enabling server support.
        #
        # Probing and waiting is necessary to resolve a bootstrap race between server and db:
        # 1. puppetdb settings (puppetdb.yaml) are enabled in Pontoon for the first time
        # 2. the puppetdb host has not yet completed its bootstrap/initialization
        # 3. puppet runs on the server host and enables puppetdb
        #
        # At this point the server has enabled a non-functional puppetdb and all future puppet runs will
        # fail (including puppet runs that might be needed by puppetdb to finish bootstrapping,
        # thus requiring manual intervention to break the race)
        #
        # Therefore enable puppetdb only when we're reasonably sure the server won't self-sabotage.
        $candidate_urls = $puppetdb_hosts.map |$h| { "https://${h}:8443" }
        $probes = join($candidate_urls, ' ')
        exec { 'probe puppetdb':
            command => "/usr/local/bin/probe-puppetdb ${puppetdb_ok_file} ${probes}",
            creates => $puppetdb_ok_file,
        }

        # Successful probing, enable puppetdb
        $puppetdb_urls = find_file($puppetdb_ok_file) ? {
            undef   => [],
            default => $candidate_urls,
        }
    }

    class { 'profile::puppetserver':
        ca_allow_san  => true,
        ca_name       => 'pontoon',
        puppetdb_urls => $puppetdb_urls,
    }

    class { 'puppetmaster::gitsync':
        base_dir => $git_basedir,
        git_user => 'puppet',
    }

    class { 'pontoon::geoip':
        base_dir => "${extra_mounts['volatile']}/GeoIP"
    }

    # Co-locate a root PKI when requested.
    # Obtaining certs requires a separate role::pki::multirootca host.
    if $pki_enabled and pontoon::hosts_for_role('pki::multirootca') != undef {
        include profile::pki::client
        include profile::pki::root_ca
        # lint:ignore:wmf_styleguide
        $intermediates = lookup('profile::pki::root_ca::intermediates', {'default_value' => []})
        $rsa_intermediates = lookup('profile::pki::root_ca::rsa_intermediates', {'default_value' => []})
        $root_ca_name = lookup('profile::pki::root_ca::common_name', {'default_value' => ''})
        # lint:endignore

        class { 'pontoon::pki_root':
            intermediates => $intermediates + $rsa_intermediates,
            root_ca_name  => $root_ca_name,
            volatile      => $extra_mounts['volatile'],
        }
    }

    if $zk_enabled {
        include profile::zookeeper::server
        include profile::zookeeper::firewall
    }

    # For users to setup their 'git push'-able repos
    file { '/usr/local/bin/pontoon-setup-repo':
        ensure => present,
        source => 'puppet:///modules/pontoon/bootstrap/pontoon-setup-repo.sh',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    # XXX refactor to use profile::puppetserver::git instead
    git::clone { 'netbox-hiera':
        ensure    => present,
        origin    => 'https://netbox-exports.wikimedia.org/netbox-hiera',
        owner     => 'puppet',
        mode      => '0755',
        directory => "${git_basedir}/netbox-hiera",
    }

    file { '/etc/puppet/netbox':
        ensure => link,
        target => "${git_basedir}/netbox-hiera",
    }
}
