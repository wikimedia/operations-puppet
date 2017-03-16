# Provisions the Wikimedia Transparency Report static site
# hosted at <http://transparency.wikimedia.org>.
#
class profile::microsites::transparency {

    include ::passwords::misc::private_static_site
    include ::passwords::ldap::production

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
        content => template('role/apache/sites/transparency.wikimedia.org.erb'),
    }

    include ::base::firewall

    ferm::service { 'transparency_http':
        proto => 'tcp',
        port  => '80',
    }
}
