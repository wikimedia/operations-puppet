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
#    - $workers:
#        Array of hashes in the form. If 'loadfactor' is omitted, it is assumed to
#        be equal to 1.
#        An 'offline' parameter is supported to allow fully depooling a host
#        without removing it from the stanza.
#         [{ 'worker' => 'worker1.example.com', loadfactor => '1' }]
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
#    - $puppet_major_version
#        The major puppet version to configure
class puppetmaster(
    $server_name='puppet',
    $bind_address='*',
    $verify_client='optional',
    $deny_from=[],
    $server_type='standalone',
    $workers=undef,
    $config={},
    $allow_from = [
        '*.wikimedia.org',
        '*.eqiad.wmnet',
        '*.ulsfo.wmnet',
        '*.esams.wmnet',
        '*.codfw.wmnet',
        '*.eqsin.wmnet',
    ],
    $is_git_master=false,
    $hiera_config=$::realm,
    $secure_private=true,
    $extra_auth_rules='',
    $prevent_cherrypicks=true,
    $git_user='gitpuppet',
    $git_group='gitpuppet',
    $puppet_major_version=undef,
    $puppetdb_major_version=undef,
){

    $gitdir = '/var/lib/git'
    $volatiledir = '/var/lib/puppet/volatile'

    # Require /etc/puppet.conf to be in place,
    # so the postinst scripts do the right things.
    class { '::puppetmaster::config':
        config      => $config,
        server_type => $server_type,
    }

    # this seems redundant because the puppetdb "termius" package is required in
    # puppetmaster::puppetdb::client, but I don't want to break something -herron
    if $puppetdb_major_version == 4 {
        $puppetdb_terminus_package = 'puppetdb-termini'
    } else {
        $puppetdb_terminus_package = 'puppetdb-terminus'
    }

    # Install the puppetdb-terminus package, needed for puppetdbquery
    require_package($puppetdb_terminus_package)

    # puppetmaster package name changed to puppet-master with version 4
    $puppetmaster_package_name = $puppet_major_version ? {
        4       => 'puppet-master',
        default => 'puppetmaster',
    }

    package { [
        $puppetmaster_package_name,
        'vim-puppet',
        'puppet-el',
        'rails',
        'ruby-json',
        'ruby-mysql',
        ]:
        ensure  => present,
    }

    if os_version('debian == jessie') {
        # Until we use activerecord
        package { 'ruby-activerecord-deprecated-finders':
            ensure => present,
        }
    }

    class { '::puppetmaster::passenger':
        bind_address         => $bind_address,
        verify_client        => $verify_client,
        allow_from           => $allow_from,
        deny_from            => $deny_from,
        puppet_major_version => $puppet_major_version,
    }

    $ssl_settings = ssl_ciphersuite('apache', 'compat')

    # path and name change with puppet 4 packages
    $puppetmaster_rack_path = $puppet_major_version ? {
        4       => '/usr/share/puppet/rack/puppet-master',
        default => '/usr/share/puppet/rack/puppetmasterd',
    }

    # Part dependent on the server_type
    case $server_type {
        'frontend': {
            include ::apache::mod::proxy
            include ::apache::mod::proxy_http
            include ::apache::mod::proxy_balancer
            include ::apache::mod::lbmethod_byrequests

            apache::site { 'puppetmaster.wikimedia.org':
                ensure => absent,
            }

            apache::site { 'puppetmaster-backend':
                content      => template('puppetmaster/puppetmaster-backend.conf.erb'),
            }
        }
        'backend': {
            apache::site { 'puppetmaster-backend':
                content => template('puppetmaster/puppetmaster-backend.conf.erb'),
            }
        }
        default: {
            apache::site { 'puppetmaster.wikimedia.org':
                content => template('puppetmaster/puppetmaster.erb'),
            }
        }
    }

    class { '::puppetmaster::ssl':
        server_name => $server_name,
    }

    class { '::puppetmaster::gitclone':
        secure_private      => $secure_private,
        is_git_master       => $is_git_master,
        prevent_cherrypicks => $prevent_cherrypicks,
        user                => $git_user,
        group               => $git_group,
    }

    class { '::puppetmaster::monitoring' :
        puppet_major_version => $puppet_major_version,
    }

    if has_key($config, 'storeconfigs_backend') and $config['storeconfigs_backend'] == 'puppetdb' {
        $has_puppetdb = true
    } else {
        $has_puppetdb = false
    }

    class { '::puppetmaster::scripts' :
        has_puppetdb => $has_puppetdb
    }

    include ::puppetmaster::geoip
    include ::puppetmaster::gitpuppet
    include ::puppetmaster::generators


    # deploy updated auth template to puppet 4 masters
    $puppetmaster_auth_template = $puppet_major_version ? {
        4       => 'auth-master-v4.conf.erb',
        default => 'auth-master.conf.erb',
    }

    file { '/etc/puppet/auth.conf':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template("puppetmaster/${puppetmaster_auth_template}"),
    }

    # Use hiera 3 backend configs on production stretch masters (stretch has hiera version 3)
    # limit to production realm until a labs_hiera3.hiera.yaml is created
    if os_version('debian >= stretch') and $::realm == 'production' {
        $hiera_source = "puppet:///modules/puppetmaster/${hiera_config}_hiera3.hiera.yaml"
    } else {
        $hiera_source = "puppet:///modules/puppetmaster/${hiera_config}.hiera.yaml"
    }

    # This is required for the mwyaml hiera backend
    require_package('ruby-httpclient')
    class { '::puppetmaster::hiera':
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
    file { '/usr/local/bin/puppet-wildcardsign':
        ensure => absent,
    }
}
