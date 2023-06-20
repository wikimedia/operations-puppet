# SPDX-License-Identifier: Apache-2.0
# @param hiera_data_dir the default location for hiera data
# @param hierarchy a hash of hierarchy to add to the hiera file
# @param code_dir the location where puppet looks for code
# @param reports list of reports to configure
# @param puppetdb_urls if present puppetdb will be configured using these urls
# @param enc_path path to an enc to use
# @param enc_source puppet file source for enc
# @param max_active_instances number of jruby instances to start, defaults to
#        cpu count, this effectively is the max concurrency for compilation
# @param listen_host host to bind webserver socket
# @param server_id hostname for metrics and ca_server
# @param autosign if true autosign agent certs
# @param enable_ca indicate if the ca is enabled
# @param intermediate_ca configure puppet Ca with an intermediate CA
# @param ca_public_key location of the ihntermediate ca content
# @param ca_crl location of the ihntermediate crl content
# @param ca_private_key_secret the content of the W
# @param git_pull whether to pull puppet code from git, defaults to true
class profile::puppetserver (
    Stdlib::Unixpath               $code_dir              = lookup('profile::puppetserver::code_dir'),
    Stdlib::Unixpath               $hiera_data_dir        = lookup('profile::puppetserver::hiera_data_dir'),
    Array[Puppetserver::Hierarchy] $hierarchy             = lookup('profile::puppetserver::hierarchy'),
    Array[Puppetserver::Report,1]  $reports               = lookup('profile::puppetserver::reports'),
    Array[Stdlib::HTTPUrl]         $puppetdb_urls         = lookup('profile::puppetserver::puppetdb_urls'),
    Optional[Stdlib::Unixpath]     $enc_path              = lookup('profile::puppetserver::enc_path'),
    Optional[Stdlib::Filesource]   $enc_source            = lookup('profile::puppetserver::enc_source'),
    Optional[Integer[1]]           $max_active_instances  = lookup('profile::puppetserver::max_active_instances', { 'default_value' => undef }),
    Optional[Stdlib::Host]         $listen_host           = lookup('profile::puppetserver::listen_host', { 'default_value' => undef }),
    Optional[Stdlib::Fqdn]         $server_id             = lookup('profile::puppetserver::server_id', { 'default_value' => undef }),
    Boolean                        $autosign              = lookup('profile::puppetserver::autosign', { 'default_value' => false }),
    Boolean                        $git_pull              = lookup('profile::puppetserver::git_pull', { 'default_value' => true }),
    Boolean                        $separate_ssldir       = lookup('profile::puppetserver::separate_ssldir'),
    Boolean                        $enable_ca             = lookup('profile::puppetserver::enable_ca'),
    Boolean                        $intermediate_ca       = lookup('profile::puppetserver::intermediate_ca'),
    Optional[Stdlib::Filesource]   $ca_public_key         = lookup('profile::puppetserver::ca_public_key'),
    Optional[Stdlib::Filesource]   $ca_crl                = lookup('profile::puppetserver::ca_crl'),
    Optional[String]               $ca_private_key_secret = lookup('profile::puppetserver::ca_private_key_secret')

) {
    if $git_pull {
        # TODO: update to use sysuseres and make a profile
        class { 'puppetmaster::gitpuppet': }
        include profile::puppetserver::git
        $g10k_sources = {
            'production'  => {
                'remote'  => $profile::puppetserver::git::control_repo_dir,
            },
        }
    } else {
        $g10k_sources = {}
    }

    $exluded_args = [
        'enc_source', 'git_pull', 'enable_ca', 'intermediate_ca',
        'ca_public_key', 'ca_crl', 'ca_private_key_secret',
    ]
    class { 'puppetserver':
        *            => wmflib::resource::filter_params($exluded_args),
        g10k_sources => $g10k_sources,
    }
    $ca_private_key = $ca_private_key_secret.then |$x| { Sensitive(secret($x)) }
    class { 'puppetserver::ca':
        enable          => $enable_ca,
        intermediate_ca => $intermediate_ca,
        ca_public_key   => $ca_public_key,
        ca_crl          => $ca_crl,
        ca_private_key  => $ca_private_key,
    }

    ferm::service { 'puppetserver':
        srange => '$DOMAIN_NETWORKS',
        proto  => 'tcp',
        port   => 8140,
    }

    if $enc_source and $enc_path {
        file { $enc_path:
            ensure => file,
            source => $enc_source,
            owner  => 'root',
            group  => 'root',
            mode   => '0555',
        }
    }
}
