# @summry This class installs a Puppetmaster
#
# @param server_name name of the server
# @param bind_address The IP address Apache will bind to
# @param verify_client Whether apache mod_ssl will verify the client (SSLVerifyClient option)
# @param server_type frontend, backend or standalone
# @param config Hash containing all config settings for the [master] section of puppet.conf (ini-style)
# @param hiera_config Specifies which file to use for hiera.yaml.
# @param is_git_master If True, the git private repository here will be considered a master
# @param secure_private If true, some magic is done to have local repositories and sync between puppetmasters.
#        Otherwise, /etc/puppet/private will be labs/private.git.
# @param extra_auth_rules extra authentication rules to add before the default policy.
# @param prevent_cherrypicks use git hooks to prevent cherry picking on top of the git repo
# @param git_user name of user who should own the git repositories
# @param git_group name of group which should own the git repositories
# @param enable_geoip Provision puppetmaster::geoip for serving clients who use the
#         geoip::data::puppet class in their manifests
# @param ca_server FQDN of the CA server
# @param ssl_verify_depth Depth to verify client certificates
# @param netbox_hiera_enable add the netbox-hiera repo
# @param enable_merge_cli whether to use the puppet-merge tool to manage git updates
# @param use_r10k Weather to use r10k
# @param upload_facts weather to upload facts to pcc
#   https://wikitech.wikimedia.org/wiki/Help:Puppet-compiler#Updating_nodes
# @param r10k_sources the r10k sources to configure
# @param servers Hash of puppetmaster servers, their workers and loadfactors
# @param http_proxy The http_proxy to use if required
# @param realm_override
#   this is use to override the realm used for the facts upload. its only really
#   used if you have two puppet masteres in the same projects servicing different
#   clients e.g. cloudinfra

#
class puppetmaster(
    String[1]                                $server_name        = 'puppet',
    String[1]                                $bind_address       = '*',
    Httpd::SSLVerifyClient                   $verify_client      = 'optional',
    Puppetmaster::Server_type                $server_type        = 'standalone',
    Hash                                     $config             = {},
    Boolean                                  $is_git_master       = false,
    String[1]                                $hiera_config        = 'production',
    Boolean                                  $secure_private      = true,
    Boolean                                  $prevent_cherrypicks = true,
    String[1]                                $git_user            = 'gitpuppet',
    String[1]                                $git_group           = 'gitpuppet',
    Boolean                                  $enable_geoip        = true,
    Stdlib::Host                             $ca_server           = $facts['networking']['fqdn'],
    Integer[1,2]                             $ssl_verify_depth    = 1,
    Boolean                                  $use_r10k            = false,
    Boolean                                  $netbox_hiera_enable = false,
    Boolean                                  $enable_merge_cli    = false,
    Boolean                                  $upload_facts        = false,
    Hash[String, Puppetmaster::R10k::Source] $r10k_sources        = {},
    Hash[String, Puppetmaster::Backends]     $servers             = {},
    Optional[Stdlib::HTTPUrl]                $http_proxy          = undef,
    Optional[String]                         $extra_auth_rules    = undef,
    Optional[String]                         $realm_override      = undef,
    Optional[String]                         $puppet_merge_server = undef,
){

    $workers = $servers[$facts['fqdn']]
    $gitdir = '/var/lib/git'
    $volatiledir = '/var/lib/puppet/volatile'

    # This is required to talk to our custom enc
    ensure_packages(['ruby-httpclient'])

    # Require /etc/puppet.conf to be in place,
    # so the postinst scripts do the right things.
    class { 'puppetmaster::config':
        config      => $config,
        server_type => $server_type,
    }

    package { [
        'vim-puppet',
        'rails',
        'ruby-json',
        ]:
        ensure  => present,
    }

    class { 'puppetmaster::passenger':
        bind_address  => $bind_address,
        verify_client => $verify_client,
    }

    $ssl_settings = ssl_ciphersuite('apache', 'strong')

    # path and name change with puppet 4 packages
    $puppetmaster_rack_path = '/usr/share/puppet/rack/puppet-master'

    # Part dependent on the server_type
    case $server_type {
        'frontend': {

            httpd::site { 'puppetmaster.wikimedia.org':
                ensure => absent,
            }

            httpd::site { 'puppetmaster-backend':
                content      => template('puppetmaster/puppetmaster-backend.conf.erb'),
            }
        }
        'backend': {
            httpd::site { 'puppetmaster-backend':
                content => template('puppetmaster/puppetmaster-backend.conf.erb'),
            }
        }
        default: {
            httpd::site { 'puppetmaster.wikimedia.org':
                content => template('puppetmaster/puppetmaster.erb'),
            }
        }
    }

    class { 'puppetmaster::ssl':
        server_name => $server_name,
    }

    class { 'puppetmaster::gitclone':
        secure_private      => $secure_private,
        is_git_master       => $is_git_master,
        prevent_cherrypicks => $prevent_cherrypicks,
        user                => $git_user,
        group               => $git_group,
        servers             => $servers,
        netbox_hiera_enable => $netbox_hiera_enable,
        use_r10k            => $use_r10k,
        r10k_sources        => $r10k_sources,
    }

    include puppetmaster::monitoring

    if has_key($config, 'storeconfigs_backend') and $config['storeconfigs_backend'] == 'puppetdb' {
        $has_puppetdb = true
    } else {
        $has_puppetdb = false
    }

    class { 'puppetmaster::scripts' :
        has_puppetdb   => $has_puppetdb,
        upload_facts   => $upload_facts,
        http_proxy     => $http_proxy,
        realm_override => $realm_override,
    }

    $all_workers = $servers.values().map |$_workers| {
        $_workers.map |$worker| { $worker['worker'] }
    }.flatten
    $paths = {
        'ops' => {
            'repo' => '/var/lib/git/operations/puppet',
            'sha1' => '/srv/config-master/puppet-sha1.txt',
        },
        'labsprivate' => {
            'repo' => '/var/lib/git/labs/private',
            'sha1' => '/srv/config-master/labsprivate-sha1.txt',
        },
    }
    if $enable_merge_cli {
        class { 'merge_cli': # lint:ignore:wmf_styleguide
            ensure    => $enable_merge_cli.bool2str('present', 'absent'),
            ca_server => $puppet_merge_server,
            paths     => $paths,
            masters   => $servers.keys(),
            workers   => $all_workers + wmflib::role::hosts('puppetserver'),
        }
    }

    if $enable_geoip {
        class { 'puppetmaster::geoip':
            ca_server => $ca_server,
        }
    }
    include puppetmaster::gitpuppet
    include puppetserver::generators # lint:ignore:wmf_styleguide

    file { '/etc/puppet/auth.conf':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('puppetmaster/auth-master.conf.erb'),
    }

    file { '/etc/puppet/hiera.yaml':
        # We dont want global hiera when using r10k
        ensure => stdlib::ensure(!$use_r10k, 'file'),
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => "puppet:///modules/puppetmaster/hiera/${hiera_config}.yaml",
        notify => Service['apache2'],
    }

    # Small utility to generate ECDSA certs and submit the CSR to the puppet master
    file { '/usr/local/bin/puppet-ecdsacert':
        ensure => present,
        source => 'puppet:///modules/puppetmaster/puppet_ecdsacert.rb',
        mode   => '0550',
        owner  => 'root',
        group  => 'root',
    }
}
