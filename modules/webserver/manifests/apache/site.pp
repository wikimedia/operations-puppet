# Define: site
#   Configures and installs an apache virtual host file using generic_vhost.erb.
#
# Parameters:
#   $aliases=[]       - array of ServerAliases
#   $ssl="false"      - if true, sets up an ssl certificate for $title
#   $certfile=undef   - defaults to /etc/ssl/localcerts/${title}.crt
#   $certkey=undef    - defaults to "/etc/ssl/private/${title}.key
#   $docroot=undef    - defaults to: $title == 'stats.wikimedia.org', then /srv/stats.wikimedia.org
#   $custom=[]        - custom Apache config strings to put into virtual host site file
#   $includes=[]
#   $server_admin="noc@wikimedia.org",
#   $access_log       - path to access log, default: /var/log/apache2/access.log
#   $error_log        - path to error log,  default: /var/log/apache2/error.log
#   $ensure=present
#
# Usage:
#   webserver::apache::site { "mysite.wikimedia.org": aliases = ["mysite.wikimedia.com"] }
define webserver::apache::site(
    $aliases      = [],
    $ssl          = 'false',
    $certfile     = "/etc/ssl/localcerts/${title}.crt",
    $certkey      = "/etc/ssl/private/${title}.key",
    $docroot      = undef,
    $custom       = [],
    $includes     = [],
    $server_admin = 'noc@wikimedia.org',
    $access_log   = "/var/log/apache2/${title}.access.log",
    $error_log    = "/var/log/apache2/${title}.error.log",
    $ensure       = 'present',
    ) {

    if os_version('debian >= jessie || ubuntu >= trusty') {
        $ssl_settings = ssl_ciphersuite('apache-2.4', 'compat')
    } else {
        $ssl_settings = ssl_ciphersuite('apache-2.2', 'compat')
    }

    #TODO: convert to apache::site
    file { "/etc/apache2/sites-enabled/${title}":
        notify  => Service['apache2'],
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('apache/generic_vhost.erb'),
    }
}
