# == Class statistics::sites::pivot
# pivot.wikimedia.org
#
# This site is composed by two parts:
# 1) a simple Apache reverse proxy to limit the access to authenticated
#    clients (via LDAP);
# 2) a nodejs application (Imply's pivot UI) deployed via scap (not part of
#    this class).
#
# Context up to September 2016:
# There is a current dispute between Imply and Metamarkets about a possible
# copyright infringement related to Imply's pivot UI.
# The Analytics team set a while back a goal to provide a Pivot UI
# to their users with the assumption that all the code
# used/deployed was open souce and freely available. If this assumption will
# change in the future, for example after a legal sentence, the Analytics team
# will take the necessary actions.
# For any question please reach out to the Analytics team:
# https://www.mediawiki.org/wiki/Analytics#Contact
#
# Bug: T138262
#
class statistics::sites::pivot {
    require ::statistics::web

    include ::apache::mod::proxy_http
    include ::apache::mod::proxy
    include ::apache::mod::auth_basic
    include ::apache::mod::authnz_ldap
    include ::passwords::ldap::production

    $proxypass = $passwords::ldap::production::proxypass

    # Set up the VirtualHost
    apache::site { 'pivot.wikimedia.org':
        content => template('statistics/pivot.wikimedia.org.erb'),
    }

    ferm::service { 'pivot-http':
        proto => 'tcp',
        port  => '80',
    }

}