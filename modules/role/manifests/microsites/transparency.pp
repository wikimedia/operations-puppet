# == Class: role::transparency
#
# This role provisions the Wikimedia Transparency Report static site,
# hosted at <http://transparency.wikimedia.org>.
#
class role::microsites::transparency {
    include ::apache
    include ::apache::mod::authnz_ldap
    include ::apache::mod::rewrite
    include ::apache::mod::headers

    include ::passwords::misc::private_static_site
    include ::passwords::ldap::production

    include base::firewall

    $repo_dir = '/srv/org/wikimedia/TransparencyReport'
    $docroot  = "${repo_dir}/build"

    $private_repo_dir = "${repo_dir}-private"
    $private_docroot = "${private_repo_dir}/build"

    git::clone { 'wikimedia/TransparencyReport':
        ensure    => latest,
        directory => $repo_dir,
    }

    $user = $passwords::misc::private_static_site::user
    $pass = $passwords::misc::private_static_site::pass

    git::clone { 'wikimedia/TransparencyReport-private':
        ensure    => latest,
        origin    => "https://${user}:${pass}@gerrit.wikimedia.org/r/wikimedia/TransparencyReport-private",
        directory => $private_repo_dir,
    }

    # LDAP configuration. Interpolated into the Apache site template
    # to provide mod_authnz_ldap-based user authentication.
    $auth_ldap = {
        name          => 'ops/wmf',
        bind_dn       => 'cn=proxyagent,ou=profile,dc=wikimedia,dc=org',
        bind_password => $passwords::ldap::production::proxypass,
        url           => 'ldaps://ldap-labs.eqiad.wikimedia.org ldap-labs.codfw.wikimedia.org/ou=people,dc=wikimedia,dc=org?cn',
        groups        => [
            'cn=ops,ou=groups,dc=wikimedia,dc=org',
            'cn=wmf,ou=groups,dc=wikimedia,dc=org',
        ],
    }

    apache::site { 'transparency.wikimedia.org':
        content => template('apache/sites/transparency.wikimedia.org.erb'),
    }

    ferm::service { 'transparency_http':
        proto => 'tcp',
        port  => '80',
    }
}
