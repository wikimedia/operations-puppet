# Definition: apache::vhost
#
# This class installs Apache Virtual Hosts
#
# Parameters:
# - The $port to configure the host on
# - The $docroot provides the DocumentationRoot variable
# - The $serveradmin will specify an email address for Apache that it will
#   display when it renders one of it's error pages
# - The $ssl option is set true or false to enable SSL for this Virtual Host
# - The $template option specifies whether to use the default template or
#   override
# - The $priority of the site
# - The $servername is the primary name of the virtual host
# - The $serveraliases of the site
# - The $options for the given vhost
# - The $override for the given vhost (array of AllowOverride arguments)
# - The $vhost_name for name based virtualhosting, defaulting to *
# - The $logroot specifies the location of the virtual hosts logfiles, default
#   to /var/log/<apache log location>/
# - The $ensure specifies if vhost file is present or absent.
#
# Actions:
# - Install Apache Virtual Hosts
#
# Requires:
# - The apache class
#
# Sample Usage:
#  apache::vhost { 'site.name.fqdn':
#    priority => '20',
#    port => '80',
#    docroot => '/path/to/docroot',
#  }
#
define apache::vhost(
    $port,
    $docroot,
    $docroot_owner      = 'root',
    $docroot_group      = 'root',
    $docroot_dir_order  = 'allow,deny',
    $docroot_dir_allows = ['all'],
    $docroot_dir_denies = '',
    $serveradmin        = false,
    $ssl                = true,
    $template           = 'apache/vhost-default.conf.erb',
    $priority           = '25',
    $servername         = '',
    $serveraliases      = '',
    $auth               = false,
    $redirect_ssl       = false,
    $options            = 'Indexes FollowSymLinks MultiViews',
    $override           = 'None',
    $vhost_name         = '*',
    $logroot            = '/var/log/apache2',
    $ensure             = 'present'
) {
    validate_re($ensure, '^(present|absent)$', "ensure must be 'present' or 'absent' (got: '${ensure}')")

    include ::apache

    if $servername == '' {
        $srvname = $name
    } else {
        $srvname = $servername
    }

    if $ssl == true {
        include apache::mod::ssl
    }

    # Since the template will use auth, redirect to https requires mod_rewrite
    if $redirect_ssl == true {
        include apache::mod::rewrite
    }

    # This ensures that the docroot exists
    # But enables it to be specified across multiple vhost resources
    if ! defined(File[$docroot]) {
        file { $docroot:
            ensure => directory,
            owner  => $docroot_owner,
            group  => $docroot_group,
        }
    }

    # Same as above, but for logroot
    if ! defined(File[$logroot]) {
        file { $logroot:
            ensure => directory,
        }
    }

    file { "${priority}-${name}.conf":
        ensure  => $ensure,
        path    => "/etc/apache2/sites-enabled/${priority}-${name}.conf",
        content => template($template),
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        require => [
            Package['httpd'],
            File[$docroot],
            File[$logroot],
        ],
        notify  => Service['httpd'],
    }
}
