# SPDX-License-Identifier: Apache-2.0
# = class: scap::master
#
# Sets up a scap master (currently deploy1002 and deploy2002)
class scap::master(
    Stdlib::Unixpath $common_path        = '/srv/mediawiki',
    Stdlib::Unixpath $common_source_path = '/srv/mediawiki-staging',
    Stdlib::Unixpath $patches_path       = '/srv/patches',
    Stdlib::Unixpath $scap_source_path   = '/srv/deployment/scap',
    String $deployment_group             = 'wikidev',
    Array[String] $deployment_hosts      = [],
){
    include network::constants

    # Required git package is provided by base::standard_packages class
    # Required bash-completion package is a standard priority Debian package and therefore installed by default
    ensure_packages([
        'python3-venv',
        'python3-service-checker',
        'python3-pygerrit2',
    ])

    git::clone { 'operations/mediawiki-config':
        ensure             => present,
        directory          => $common_source_path,
        owner              => 'mwdeploy',
        group              => $deployment_group,
        shared             => true,
        before             => Exec['fetch_mediawiki'],
        recurse_submodules => true,
    }

    git::clone { 'repos/releng/scap':
        ensure    => present,
        source    => 'gitlab',
        directory => $scap_source_path,
        owner     => 'scap',
        group     => $deployment_group,
        shared    => true,
    }

    file { $patches_path:
        ensure => 'directory',
        owner  => 'mwdeploy',
        group  => $deployment_group,
        mode   => '2775',
    }

    # Install the commit-msg hook from gerrit

    file { "${common_source_path}/.git/hooks/commit-msg":
        ensure  => present,
        owner   => 'mwdeploy',
        group   => $deployment_group,
        mode    => '0775',
        source  => 'puppet:///modules/scap/commit-msg',
        require => Git::Clone['operations/mediawiki-config'],
    }

    ## Bootstrap Scap

    # This dir needs to match the home of the user defined in class scap::user
    $scap_home = '/var/lib/scap'

    exec { 'bootstrap_scap_master':
      command => "${scap_source_path}/bin/bootstrap_scap_master.sh scap ${scap_source_path}",
      creates => "${scap_home}/scap/bin/scap",
    }

    file { '/usr/bin/scap':
      ensure  => 'link',
      target  => "${scap_home}/scap/bin/scap",
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      require => Exec['bootstrap_scap_master']
    }

    rsync::server::module { 'scap-install-staging':
      path        => $scap_home,
      read_only   => 'yes',
      hosts_allow => join($::network::constants::deployable_networks, ' ')
    }

    ## End bootstrap Scap

    rsync::server::module { 'common':
        path        => $common_source_path,
        read_only   => 'yes',
        hosts_allow => $::network::constants::mw_appserver_networks;
    }

    rsync::server::module { 'patches':
        path        => $patches_path,
        read_only   => 'yes',
        hosts_allow => $deployment_hosts
    }

    class { 'scap::l10nupdate':
        deployment_group => $deployment_group,
        run_l10nupdate   => false,
    }

    file { '/usr/local/bin/scap-master-sync':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/scap/scap-master-sync',
    }

    # Allow rsync of common module to mediawiki-staging as root.
    # This is for master-master sync of /srv/mediawiki-staging
    sudo::user { 'scap-master-sync':
        user       => 'mwdeploy',
        privileges => [
            'ALL = (root) NOPASSWD: /usr/local/bin/scap-master-sync',
        ]
    }

    wmflib::dir::mkdir_p('/etc/scap')

    # T315255
    file { '/etc/scap/phabricator_token':
        ensure    => present,
        owner     => 'root',
        group     => $deployment_group,
        mode      => '0440',
        content   => secret('scap/phabricator_token'),
        show_diff => false,
    }
}
