# == Class: profile::webperf::xhgui
#
# This class is still a work in progress!
# See https://phabricator.wikimedia.org/T180761.
#
# Provision XHGui, a graphical interface for XHProf data
# built on MongoDB. Used by the Performance Team.
#
# See also profile::webperf::site, which provisions a proxy
# to expose the service at <https://performance.wikimedia.org/xhgui/>.
#
class profile::webperf::xhgui (
    $ldap_config    = lookup('ldap', Hash, hash, {}),
    $mysql_host     = lookup('profile::webperf::xhgui::mysql_host'),
    $mysql_db       = lookup('profile::webperf::xhgui::mysql_db'),
    $mysql_user     = lookup('profile::webperf::xhgui::mysql_user'),
    $mysql_password = lookup('profile::webperf::xhgui::mysql_password'),
) {
    include ::passwords::ldap::production

    # Package xhgui (and dependencies) is built from performance/debs
    require_package('libapache2-mod-php7.3', 'php7.3-mysql')

    # php-twig 1.24.0 is from stretch.  We've rebuilt it for buster but the
    # older version needs to be pinned in order for apt to use it.  (xhgui is
    # not yet compatible with newer versions.)
    if os_version('debian == buster') {
        apt::pin { 'php-twig':
            pin      => 'version 1.*',
            package  => 'php-twig',
            priority => '1001',
            before   => Package['xhgui'],
        }
    }

    package { 'xhgui':
        ensure => 'present',
    }

    ferm::service { 'webperf-xhgui-http':
        proto  => 'tcp',
        port   => '80',
        srange => '$DOMAIN_NETWORKS',
    }

    $auth_ldap = {
        name          => 'nda/ops/wmf',
        bind_dn       => 'cn=proxyagent,ou=profile,dc=wikimedia,dc=org',
        bind_password => $passwords::ldap::production::proxypass,
        url           => "ldaps://${ldap_config[ro-server]} ${ldap_config[ro-server-fallback]}/ou=people,dc=wikimedia,dc=org?cn",
        groups        => [
            'cn=ops,ou=groups,dc=wikimedia,dc=org',
            'cn=nda,ou=groups,dc=wikimedia,dc=org',
            'cn=wmf,ou=groups,dc=wikimedia,dc=org',
        ],
    }

    file { 'config.php':
        ensure  => file,
        path    => '/etc/xhgui/config.php',
        content => template('profile/webperf/xhgui/config.php.erb'),
        owner   => 'www-data',
        mode    => '0600',
        require => Package['xhgui'],
    }

    $webroot_dir = '/usr/share/xhgui/webroot'

    httpd::site { 'xhgui_apache_site':
        content => template('profile/webperf/xhgui/httpd.conf.erb'),
    }
}
