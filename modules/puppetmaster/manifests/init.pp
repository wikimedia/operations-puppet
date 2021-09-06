# Class: puppetmaster
#
# This class installs a Puppetmaster
#
# Parameters
#    - $bind_address:
#        The IP address Apache will bind to
#    - $verify_client:
#        Whether apache mod_ssl will verify the client (SSLVerifyClient option)
#    - $allow_from:
#        Adds an Allow from statement (order Allow,Deny), limiting access
#        to the passenger service.
#    - $deny_from:
#        Adds a Deny from statement (order Allow,Deny), limiting access
#        to the passenger service.
#    - $config:
#        Hash containing all config settings for the [master] section of
#        puppet.conf (ini-style)
#    - $hiera_config:
#        Specifies which file to use for hiera.yaml.  Defaults to $::realm
#    - $is_git_master:
#        If True, the git private repository here will be considered a master
#    - $secure_private:
#        If true, some magic is done to have local repositories and sync between puppetmasters.
#        Otherwise, /etc/puppet/private will be labs/private.git.
#    - $extra_auth_rules:
#        String - extra authentication rules to add before the default policy.
#    - $prevent_cherrypicks:
#        Bool - use git hooks to prevent cherry picking on top of the git repo
#    - $git_user
#        String - name of user who should own the git repositories
#    - $git_group
#        String - name of group which should own the git repositories
#    - $enable_geoip
#        Bool - Provision ::puppetmaster::geoip for serving clients who use
#        the ::geoip::data::puppet class in their manifests
#    - $servers
#        Hash - Hash of puppetmaster servers, their workers and loadfactors
#
class puppetmaster(
    String[1]                        $server_name        = 'puppet',
    String[1]                        $bind_address       = '*',
    Httpd::SSLVerifyClient           $verify_client      = 'optional',
    Array[String]                    $deny_from          = [],
    Puppetmaster::Server_type        $server_type        = 'standalone',
    Hash                             $config             = {},
    Array[String]                    $allow_from         = [
                                                            '*.wikimedia.org',
                                                            '*.eqiad.wmnet',
                                                            '*.ulsfo.wmnet',
                                                            '*.esams.wmnet',
                                                            '*.codfw.wmnet',
                                                            '*.eqsin.wmnet',
                                                            '*.drmrs.wmnet',
                                                          ],
    Boolean                          $is_git_master       = false,
    String[1]                        $hiera_config        = $::realm,
    Boolean                          $secure_private      = true,
    String                           $extra_auth_rules    = '',
    Boolean                          $prevent_cherrypicks = true,
    String[1]                        $git_user            = 'gitpuppet',
    String[1]                        $git_group           = 'gitpuppet',
    Boolean                          $enable_geoip        = true,
    Stdlib::Host                     $ca_server           = $facts['fqdn'],
    Integer[1,2]                     $ssl_verify_depth    = 1,
    Hash[String, Puppetmaster::Backends] $servers         = {},
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
        allow_from    => $allow_from,
        deny_from     => $deny_from,
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
    }

    include puppetmaster::monitoring

    if has_key($config, 'storeconfigs_backend') and $config['storeconfigs_backend'] == 'puppetdb' {
        $has_puppetdb = true
    } else {
        $has_puppetdb = false
    }

    class { 'puppetmaster::scripts' :
        servers      => $servers,
        has_puppetdb => $has_puppetdb,
        ca_server    => $ca_server,
    }

    if $enable_geoip {
        class { 'puppetmaster::geoip': }
    }
    include puppetmaster::gitpuppet
    include puppetmaster::generators

    file { '/etc/puppet/auth.conf':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('puppetmaster/auth-master.conf.erb'),
    }

    $hiera_source = "puppet:///modules/puppetmaster/${hiera_config}.hiera.yaml"

    class { 'puppetmaster::hiera':
        source => $hiera_source,
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
