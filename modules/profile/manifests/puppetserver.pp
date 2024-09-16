# SPDX-License-Identifier: Apache-2.0
# @param hiera_data_dir the default location for hiera data
# @param hierarchy a hash of hierarchy to add to the hiera file
# @param java_start_mem the value to use for the java args -Xms
# @param java_max_mem the value to use for the java args -Xmx
# @param code_dir the location where puppet looks for code
# @param reports list of reports to configure
# @param puppetdb_urls if present puppetdb will be configured using these urls
# @param puppetdb_submit_only_urls if present puppetdb will be configured to also use these urls for writes
# @param enc_path path to an enc to use
# @param enc_source puppet file source for enc
# @param max_active_instances number of jruby instances to start, defaults to
#        cpu count, this effectively is the max concurrency for compilation
# @param listen_host host to bind webserver socket
# @param server_id hostname for metrics and ca_server
# @param autosign if true autosign agent certs, if a path then use that script to validate
# @param ca_server the fqdn of the ca_server
# @param intermediate_ca configure puppet Ca with an intermediate CA
# @param ca_public_key location of the intermediate ca content
# @param ssldir_on_srv used on cloud-vps; it allows storing certs on a detachable volume
# @param separate_ssldir used when the puppetserver is managed by a different puppet server #TODO remove this setting in favor of ssldir_on_srv
# @param ca_crl location of the intermediate crl content
# @param ca_private_key_secret the content of the W
# @param ca_allow_san whether to allow agents to request SANs
# @param ca_name override the default Puppet CA name
# @param strict_mode enable "strict mode", same as defaults in Puppet 8, https://github.com/puppetlabs/puppet/wiki/Puppet-8-Compatibility#strict-mode
# @param git_pull whether to pull puppet code from git, defaults to true
# @param auto_restart if true changes to config files will cause the puppetserver to either restart or
#   reload the puppetserver service
# @param enable_jmx
# @param extra_mounts hash of mount point name to path, mount point name will used in puppet:///<MOUNT POINT>
# @param environment_timeout, number of seconds to cache code from an environment, or unlimited to never evict the cache
class profile::puppetserver (
    Stdlib::Fqdn                       $server_id                 = lookup('profile::puppetserver::server_id'),
    Stdlib::Unixpath                   $code_dir                  = lookup('profile::puppetserver::code_dir'),
    Stdlib::Unixpath                   $hiera_data_dir            = lookup('profile::puppetserver::hiera_data_dir'),
    Stdlib::Datasize                   $java_start_mem            = lookup('profile::puppetserver::java_start_mem'),
    Stdlib::Datasize                   $java_max_mem              = lookup('profile::puppetserver::java_max_mem'),
    Array[Puppetserver::Hierarchy]     $hierarchy                 = lookup('profile::puppetserver::hierarchy'),
    Array[Puppetserver::Report,1]      $reports                   = lookup('profile::puppetserver::reports'),
    Array[Stdlib::HTTPUrl]             $puppetdb_urls             = lookup('profile::puppetserver::puppetdb_urls'),
    Array[Stdlib::HTTPUrl]             $puppetdb_submit_only_urls = lookup('profile::puppetserver::puppetdb_submit_only_urls'),
    Optional[Stdlib::Unixpath]         $enc_path                  = lookup('profile::puppetserver::enc_path'),
    Optional[Stdlib::Filesource]       $enc_source                = lookup('profile::puppetserver::enc_source'),
    Optional[Integer[1]]               $max_active_instances      = lookup('profile::puppetserver::max_active_instances', { 'default_value' => undef }),
    Optional[Stdlib::Host]             $listen_host               = lookup('profile::puppetserver::listen_host', { 'default_value' => undef }),
    Variant[Boolean, Stdlib::Unixpath] $autosign                  = lookup('profile::puppetserver::autosign', { 'default_value' => false }),
    Boolean                            $git_pull                  = lookup('profile::puppetserver::git_pull', { 'default_value' => true }),
    Boolean                            $ssldir_on_srv             = lookup('profile::puppetserver::ssldir_on_srv'),
    Boolean                            $separate_ssldir           = lookup('profile::puppetserver::separate_ssldir'),
    Stdlib::Fqdn                       $ca_server                 = lookup('profile::puppetserver::ca_server'),
    Boolean                            $intermediate_ca           = lookup('profile::puppetserver::intermediate_ca'),
    Boolean                            $enable_jmx                = lookup('profile::puppetserver::enable_jmx'),
    Boolean                            $auto_restart              = lookup('profile::puppetserver::auto_restart'),
    Optional[Stdlib::Filesource]       $ca_public_key             = lookup('profile::puppetserver::ca_public_key'),
    Optional[Stdlib::Filesource]       $ca_crl                    = lookup('profile::puppetserver::ca_crl'),
    Optional[String]                   $ca_private_key_secret     = lookup('profile::puppetserver::ca_private_key_secret'),
    Boolean                            $ca_allow_san              = lookup('profile::puppetserver::ca_allow_san'),
    Optional[String[1]]                $ca_name                   = lookup('profile::puppetserver::ca_name'),
    Boolean                            $strict_mode               = lookup('profile::puppetserver::strict_mode', { 'default_value' => true }),
    Hash[String, Stdlib::Unixpath]     $extra_mounts              = lookup('profile::puppetserver::extra_mounts'),
    Variant[
        Enum['unlimited'],
        Integer
    ]                                  $environment_timeout       = lookup('profile::puppetserver::environment_timeout'),
    Optional[Stdlib::Host]             $puppet_merge_server       = lookup('puppet_merge_server'),
) {
    $enable_ca = $ca_server == $facts['networking']['fqdn']
    if $git_pull {
        include profile::puppetserver::git
        $paths = {
            'ops'  => {
                'repo' => $profile::puppetserver::git::control_repo_dir,
                # TODO: link this with config master profile
                'sha1' => '/srv/config-master/puppet-sha1.txt',
            },
            # We have labsprivate on the puppetservers to ensure that we validate changes via
            # puppet-merge. Specifically we dont want the WMCS puppetserveres accidentally running
            # malicious modules injected into the private repo.  And to a lesser extent any
            # vulnerabilities that may be present via hiera injections.  e.g. injecting a user
            'labsprivate'  => {
                'repo' => "${profile::puppetserver::git::basedir}/labs/private",
                'sha1' => '/srv/config-master/puppet-sha1.txt',
            },
        }
        if $puppet_merge_server {
            class { 'merge_cli':
                ca_server => $puppet_merge_server,
                masters   => $profile::puppetserver::git::servers,
                workers   => $profile::puppetserver::git::servers,
                paths     => $paths,
            }
        }
        $g10k_sources = {
            'production'  => {
                'remote'  => $profile::puppetserver::git::control_repo_dir,
            },
        }
    } else {
        $g10k_sources = {}
    }

    $exluded_args = [
        'enc_source', 'git_pull', 'intermediate_ca',
        'ca_public_key', 'ca_crl', 'ca_private_key_secret',
        'puppet_merge_server',
    ]
    class { 'puppetserver':
        * => wmflib::resource::filter_params($exluded_args),
    }
    class { 'puppetserver::g10k':
        ensure  => stdlib::ensure(!$g10k_sources.empty),
        sources => $g10k_sources,
    }
    $config_dir = $puppetserver::puppetserver_config_dir
    $ssl_dir = $puppetserver::ssl_dir
    $ca_dir = $puppetserver::ca_dir
    $ca_private_key = $ca_private_key_secret.then |$x| { Sensitive(secret($x)) }
    class { 'puppetserver::ca':
        enable          => $enable_ca,
        intermediate_ca => $intermediate_ca,
        ca_public_key   => $ca_public_key,
        ca_crl          => $ca_crl,
        ca_private_key  => $ca_private_key,
    }

    # TODO: move to puppetserver class
    class { 'puppetmaster::ca_monitoring':
        ensure  => $enable_ca.bool2str('present', 'absent'),
        ca_root => $puppetserver::ca_dir,
    }

    class { 'puppetserver::generators': }

    puppetserver::rsync_module { 'ca':
        path     => $ca_dir,
        hosts    => wmflib::class::hosts('puppetserver::ca'),
        interval => {'start' => 'OnUnitInactiveSec', 'interval' => 'daily'},
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
