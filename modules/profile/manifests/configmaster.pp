# @summary A profile to configure the config-master.wikimedia.org site content
# @param conftool_prefix th conftool_prefix
# @param puppet_merge_server: The server from which Puppet changes are merged
# @param server_name the main server name
# @param server_aliases a list of alternate server names
# @param enable_nda if true enable the nda uri
# @param proxy_sha1 if true proxy the sha1's used by puppet-merge from the puppetmaster ca host
class profile::configmaster (
    Stdlib::Unixpath    $conftool_prefix     = lookup('conftool_prefix'),
    Stdlib::Fqdn        $puppet_merge_server = lookup('puppet_merge_server'),
    Stdlib::Host        $server_name         = lookup('profile::configmaster::server_name'),
    Array[Stdlib::Host] $server_aliases      = lookup('profile::configmaster::server_aliases'),
    Boolean             $enable_nda          = lookup('profile::configmaster::enable_nda'),
    Boolean             $proxy_sha1          = lookup('profile::configmaster::proxy_sha1'),
) {
    ensure_packages(['python3-conftool'])
    $real_server_aliases = $server_aliases + [
        'pybal-config',
    ]

    $document_root = '/srv/config-master'
    $protected_uri = '/nda'
    $nda_dir       = "${document_root}${protected_uri}"
    $vhost_settings = {
        'enable_nda'          => $enable_nda,
        'proxy_sha1'          => $proxy_sha1,
        'puppet_merge_server' => $puppet_merge_server,
    }

    # The installer dir is used by the reimage cookbook to pass info to late_command.sh
    file { [$document_root, "${document_root}/installer"]:
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    unless $proxy_sha1 {
        # gitpuppet can't/shouldn't be able to create files under $document_root.
        # So puppet makes sure the file at least exists, and then puppet-merge
        # can write.
        file { ["${document_root}/puppet-sha1.txt", "${document_root}/labsprivate-sha1.txt"]:
            ensure => file,
            owner  => 'gitpuppet',
            group  => 'gitpuppet',
            mode   => '0644',
        }
    }
    # copy mediawiki conftool-state file to configmaster so we can fetch it
    # from pcc and pontoon.
    file { "${document_root}/mediawiki.yaml":
        ensure => file,
        source => '/etc/conftool-state/mediawiki.yaml',
    }

    # Write pybal pools
    class { 'pybal::web':
        ensure   => present,
        root_dir => $document_root,
        services => wmflib::service::fetch(true),
    }

    # Script to dump pool states to a json file. Used by Amir's tool
    # fault-tolerance.toolforge.org
    file { '/usr/local/bin/dump-conftool-pools':
        ensure => file,
        source => 'puppet:///modules/profile/conftool/dump-pools-json.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    # Run dump-conftool-pools every 5 minutes
    systemd::timer::job { 'dump-conftool-pools':
        ensure      => present,
        user        => 'root',
        description => 'Dump pool states from conftool to a json file accessible from the web',
        command     => "/usr/local/bin/dump-conftool-pools --output ${document_root}/pools.json",
        interval    => {'start' => 'OnUnitInactiveSec', 'interval' => '5m'},
    }

    class { 'ssh::publish_fingerprints':
        document_root => $document_root,
    }

    # TLS termination
    include profile::tlsproxy::envoy
    httpd::conf { 'configmaster_port':
        content => "Listen 80\n",
    }

    file {
        default:
            ensure => stdlib::ensure($enable_nda, file),
            owner  => 'root',
            group  => 'root',
            mode   => '0444';
        "${nda_dir}/abuse_networks.txt": ;
        "${nda_dir}/README.html":
            content => '<html><head><title>NDA</title><body>Folder containing NDA protected content</body></html>';
        $nda_dir:
            ensure => stdlib::ensure($enable_nda, directory),
            mode   => '0755';
    }

    if $enable_nda {
        File["${nda_dir}/abuse_networks.txt"] {
            source => '/etc/ferm/conf.d/00_defs_requestctl'
        }
        profile::idp::client::httpd::site { $server_name:
            document_root    => $document_root,
            server_aliases   => $real_server_aliases,
            protected_uri    => $protected_uri,
            vhost_content    => 'profile/configmaster/config-master.conf.erb',
            proxied_as_https => true,
            vhost_settings   => $vhost_settings,
            required_groups  => [
                'cn=ops,ou=groups,dc=wikimedia,dc=org',
                'cn=wmf,ou=groups,dc=wikimedia,dc=org',
                'cn=nda,ou=groups,dc=wikimedia,dc=org',
            ],
        }
    } else {
        $virtual_host = $server_name
        httpd::site { 'config-master':
            ensure   => present,
            priority => 50,
            content  => template('profile/configmaster/config-master.conf.erb'),
        }
    }
    firewall::service { 'pybal_conf-http':
        proto    => 'tcp',
        port     => 80,
        src_sets => ['PRODUCTION_NETWORKS'],
    }
}
