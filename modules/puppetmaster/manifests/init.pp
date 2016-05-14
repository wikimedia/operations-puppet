# Class: puppetmaster
#
# This class installs a Puppetmaster
#
# Parameters:
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
#        Array of hashes in the form. If loadfactor is omitted, it is assumed to
#        be equal to 1
#         [{ 'worker' => 'worker1.example.com', loadfactor => '1' }]
#    - $hiera_config:
#        Specifies which file to use for hiera.yaml.  Defaults to $::realm
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
            ],
            $is_labs_master=false,
            $hiera_config=$::realm,
            ){

    $gitdir = '/var/lib/git'
    $volatiledir = '/var/lib/puppet/volatile'

    # Require /etc/puppet.conf to be in place,
    # so the postinst scripts do the right things.
    class { 'puppetmaster::config':
        config      => $config,
        server_type => $server_type,
    }

    package { [
        'puppetmaster',
        'puppetmaster-common',
        'vim-puppet',
        'puppet-el',
        'rails',
        'ruby-json',
        'ruby-mysql',
        'ruby-ldap'
        ]:
        ensure  => present,
    }

    if $server_type == 'frontend' {
        include ::apache::mod::proxy
        include ::apache::mod::proxy_http
        include ::apache::mod::proxy_balancer
    }

    class { 'puppetmaster::passenger':
        bind_address  => $bind_address,
        verify_client => $verify_client,
        allow_from    => $allow_from,
        deny_from     => $deny_from
    }

    class { 'puppetmaster::ssl':
        server_name => $server_name,
        ca          => $config['ca']
    }

    class { 'puppetmaster::gitclone':
        is_labs_master => $is_labs_master,
    }

    include puppetmaster::scripts
    include puppetmaster::geoip
    include puppetmaster::gitpuppet
    include puppetmaster::monitoring

    if $is_labs_master {
        include puppetmaster::labs
        require_package('ruby-httpclient')
    }

    class { '::puppetmaster::hiera':
        source => "puppet:///modules/puppetmaster/${hiera_config}.hiera.yaml",
    }
}
