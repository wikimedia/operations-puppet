# SPDX-License-Identifier: Apache-2.0
#
# This class is an helper class to allow you to enable the use of the HIDDENPARMA WAF in HAProxy.
# Once included in your code, it installs several lua scripts that you will need, and generates HAProxy configuration fragments
# to set the headers needed for hiddenparma to work.
# You will then need to switch your haproxy::site definition to a haproxy::confd_site definition, and include the relevant fragments in your configuration
# as follows:
# * haproxy::hiddenparma::set_headers should go at the top of your frontend definition, it takes care of cleaning up the headers you will use.
# * haproxy::hiddenparma::set_provenance should go in your frontend definition below haproxy::hiddenparma::set_headers, it sets the provenance variable based on the request.
# * If you are using the JA3N and JA4H fingerprinting, haproxy::hiddenparma::set_fingerprints should go in your frontend definition below haproxy::hiddenparma::set_provenance, it sets the headers for the fingerprints.
# * haproxy::hiddenparma::known_client_fragment should go in your frontend definition. It fetches information about known clients from HIDDENPARMA's etcd and sets the appropriate headers.
# * If you support JWT-based authentication, haproxy::hiddenparma::set_jwt_header should go in your frontend definition below haproxy::hiddenparma::known_client_fragment, it validates the JWT and sets the X-JWT-Sub header if valid.
# * haproxy::hiddenparma::set_ua_contact_header should go in your frontend definition below all of the above variables; it extracts contact information from the User-Agent header
#   and sets the req.trusted_request and X-Trusted-Request header accordingly. It also sets up ACLs to classify requests based on the value of req.trusted_request.
# * haproxy::hiddenparma::conditional_backend_selection should be used in your frontend definition to select the appropriate backend based on the trust scopes you have configured.
# * Finally, haproxy::hiddenparma::backends should be used to define the backends for the scopes defined.
#
# For a reference usage of most of these fragments, please see the profile::cache::haproxy class.
#
# @summary
#  This class provides all the files and fragments needed to enable hiddenparma in haproxy.
#
# @param use_jwt
#  Whether to enable JWT validation and the setting of the X-JWT-Sub header.
# @param use_maxmind
#  Whether to enable the use of the MaxMindDB for geolocation. Doesn't take care of installing the MaxMindDB itself, which will need to be done separately.
# @param report_ja3n
#  Whether to enable the reporting of JA3N fingerprints.
# @param report_ja4h
#  Whether to enable the reporting of JA4H fingerprints.
# @param wikimedia_trust
#  Whether to include wikimedia trusted networks in provenance determinations. You will need to provide the corresponding ACL in your code.
# @param cluster
#  The cluster name in hiddenparma to source rules from. This is used to fetch the rules from etcd.
# @param conftool_prefix
#  The prefix to use for the conftool keys. This is used to fetch the rules from etcd.
# @param location
#  The location name in hiddenparma to source rules from.
# @param actual_backend_server
#  The actual backend server to fordward requests to.
# @param jwt_key_path
#  The path to the JWT public key to use for validation, if enabled. Empty by default, but compilation will fail if use_jwt is true and this is not set to a valid path.
# @param logging_variable
#  The name of the variable to use for logging the matching rules. Defaults to 'requestctl'.
# @param provenance_variable
#  The name of the variable to use for storing the provenance information. Defaults to 'provenance'.
# @param lua_version
#  The version of Lua to use for the MaxMindDB package. Defaults to '5.3'.
class haproxy::hiddenparma (
    Boolean $use_jwt,
    Boolean $use_maxmind,
    Boolean $report_ja3n,
    Boolean $report_ja4h,
    Boolean $wikimedia_trust,
    String  $cluster,
    String  $conftool_prefix,
    String  $location,
    String  $actual_backend_server,
    Optional[Stdlib::Absolutepath]  $jwt_key_path=undef,
    String  $logging_variable='requestctl',
    String  $provenance_variable='provenance',
    String  $lua_version='5.3',
) {
    if $use_jwt and $jwt_key_path == undef {
        fail('If use_jwt is true, you must provide a valid jwt_key_path.')
    }
    ## VARIABLES TO USE IN TEMPLATES
    # This variable encapsulates the headers needed for hiddenparma.
    $set_headers = template('haproxy/hiddenparma/headers.erb')
    # This sets the provenance variable based on data in the request.
    $set_provenance = template('haproxy/hiddenparma/provenance.erb')
    # If reporting of JA3N and JA4H is enabled, this variable sets the headers for those.
    $set_fingerprints = template('haproxy/hiddenparma/fingerprints.erb')
    # Imports identification/denial rules for known clients from etcd.
    $known_client_fragment = template('haproxy/hiddenparma/known_client_fragment.erb')
    # Performs the JWT validation and sets the X-JWT-Sub header if valid.
    $set_jwt_header = $use_jwt ? {
        true  => template('haproxy/hiddenparma/jwt_headers.erb'),
        false => '',
    }
    # Extracts contact information from the User-Agent header and sets the X-Trusted-Request header accordingly.
    $set_ua_contact_header = template('haproxy/hiddenparma/uacontactinfo.erb')
    # Selects the appropriate backend based on the trust scopes you have configured.
    $conditional_backend_selection = template('haproxy/hiddenparma/conditional_backend_selection.erb')
    # Defines the backends for the scopes defined.
    $backends = template('haproxy/hiddenparma/backends.erb')

    ## INSTALLATION OF LUA MAXMINDDB PACKAGE AND SCRIPT
    package { "lua${lua_version}-maxminddb":
        ensure => $use_maxmind.bool2str('present', 'absent'),
    }

    file { '/etc/haproxy/lua/maxmind-lookup.lua':
        ensure  => $use_maxmind.bool2str('file', 'absent'),
        mode    => '0644',
        owner   => 'haproxy',
        group   => 'haproxy',
        content => file('profile/cache/maxmind-lookup.lua'),
        require => [File['/etc/haproxy/lua'], Package["lua${lua_version}-maxminddb"]],

        notify  => Service['haproxy'],
        before  => Service['haproxy'],
    }

    ## LUA FINGERPRINTING SCRIPTS
    file { '/etc/haproxy/lua/ja3n.lua':
        ensure  => $report_ja3n.bool2str('file', 'absent'),
        mode    => '0644',
        owner   => 'haproxy',
        group   => 'haproxy',
        content => file('profile/cache/ja3n.lua'),
        require => File['/etc/haproxy/lua'],
        notify  => Service['haproxy'],
        before  => Service['haproxy'],
    }

    file { '/etc/haproxy/lua/ja4h.lua':
        ensure  => $report_ja4h.bool2str('file', 'absent'),
        mode    => '0644',
        owner   => 'haproxy',
        group   => 'haproxy',
        content => file('profile/cache/ja4h.lua'),
        require => File['/etc/haproxy/lua'],
        notify  => Service['haproxy'],
        before  => Service['haproxy'],
    }

    ## LUA FOR UA CONTACT INFORMATION PARSING
    file { '/etc/haproxy/lua/contact_info.lua':
        ensure  => 'file',
        mode    => '0644',
        owner   => 'haproxy',
        group   => 'haproxy',
        content => file('profile/cache/contact_info.lua'),
        notify  => Service['haproxy'],
        before  => Service['haproxy'],
    }

    ## ADDITIONAL FILES
    # Map file of ipblocks as computed via hiddenparma.
    confd::file { '/etc/haproxy/ipblocks.d/all.map':
        ensure     => present,
        prefix     => $conftool_prefix,
        watch_keys => ['/request-haproxy-provenance-map', '/active-scopes'],
        content    => template('haproxy/hiddenparma/ipblocks.map.tpl.erb'),
        # Please, whoever sees this in the future, don't @ me about this.
        # An haproxy map file can contain either blank lines, comments,
        # or lines with key-value pairs separated by spaces.
        # The check command is a perl one-liner that checks for these three cases.
        # If you find a nicer solution that doesn't involve writing a custom
        # parser, please fix this.
        check      => '/usr/local/bin/check-haproxy-map',
        reload     => '/usr/bin/systemctl reload haproxy.service',
        before     => Service['haproxy'],
    }
}
