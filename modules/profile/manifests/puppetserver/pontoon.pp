# SPDX-License-Identifier: Apache-2.0
# Self-hosted puppetserver for a Pontoon stack

class profile::puppetserver::pontoon (
    Stdlib::Unixpath               $git_basedir  = lookup('profile::puppetserver::git::basedir'),
    Stdlib::Unixpath               $code_dir     = lookup('profile::puppetserver::code_dir'),
    Boolean                        $pki_enabled  = lookup('profile::puppetserver::pontoon::pki_enabled', {'default_value' => false}),
    Boolean                        $zk_enabled   = lookup('profile::puppetserver::pontoon::zk_enabled', {'default_value' => false}),
    Boolean                        $acme_enabled = lookup('profile::puppetserver::pontoon::acme_enabled', {'default_value' => false}),
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


        # Clone from gerrit ($origin == undef) unless we are bootstrapping.
        # In which case:
        # * clone from the local repos first
        # * once done, go back to having gerrit as a remote (by git::clone)
        # This is done in order to have puppetserver::gitsync do the right thing
        $bootstrap_dir = "/tmp/bootstrap/git/${$repo.basename}"
        $bootstrap_guard = "${bootstrap_dir}/.git/bootstrap-ok"

        $origin = (find_file($bootstrap_guard.dirname) and !find_file($bootstrap_guard)) ? {
            true    => $bootstrap_dir,
            default => undef,
        }

        exec { "repo_bootstrap_finish_${repo}":
            refreshonly => true,
            command     => "/usr/bin/touch ${bootstrap_guard}",
            creates     => $bootstrap_guard,
        }

        git::clone { $repo:
            directory => "${git_basedir}/${repo}",
            owner     => 'puppet',
            mode      => '0755',
            origin    => $origin,
            notify    => Exec["repo_bootstrap_finish_${repo}"],
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

    # in Cloud VPS agents of a self-hosted puppetserver expect
    # /var/lib/puppet/client/ssl instead of /var/lib/puppet/ssl. See also
    # modules/wmflib/lib/puppet/parser/functions/puppet_ssldir.rb
    # and the equivalent functionality in pontoon/enroll.py
    file { '/var/lib/puppet/client':
        ensure => link,
        target => '.',
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

    class { 'puppetserver::gitsync':
        base_dir => $git_basedir,
        git_user => 'puppet',
    }

    class { 'pontoon::geoip':
        base_dir => "${extra_mounts['volatile']}/GeoIP"
    }

    class { 'pontoon::netbox':
        base_dir => $git_basedir,
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
        $acme_certs = lookup('profile::acme_chief::certificates')
        # lint:endignore

        class { 'pontoon::pki_root':
            intermediates => $intermediates + $rsa_intermediates,
            root_ca_name  => $root_ca_name,
            volatile      => $extra_mounts['volatile'],
        }

        if $acme_enabled {
            class { 'pontoon::pki_acme':
                acme_certs => $acme_certs,
            }
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
}
