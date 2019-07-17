# Provisions the Wikimedia Transparency Report static site
# hosted at <http://transparency.wikimedia.org>.
#
class profile::microsites::transparency(
    $ldap_config = lookup('ldap', Hash, hash, {}),
){

    include ::passwords::ldap::production

    $repo_dir = '/srv/org/wikimedia/TransparencyReport'
    $docroot  = "${repo_dir}/build"

    $private_repo_dir = "${repo_dir}-private"
    $private_docroot = "${private_repo_dir}/build"

    git::clone { 'wikimedia/TransparencyReport':
        ensure    => latest,
        directory => $repo_dir,
    }

    # LDAP configuration. Interpolated into the Apache site template
    # to provide mod_authnz_ldap-based user authentication.
    $auth_ldap = {
        name          => 'ops/wmf/nda',
        bind_dn       => 'cn=proxyagent,ou=profile,dc=wikimedia,dc=org',
        bind_password => $passwords::ldap::production::proxypass,
        url           => "ldaps://${ldap_config[ro-server]} ${ldap_config[ro-server-fallback]}/ou=people,dc=wikimedia,dc=org?cn",
        groups        => [
            'cn=ops,ou=groups,dc=wikimedia,dc=org',
            'cn=nda,ou=groups,dc=wikimedia,dc=org',
            'cn=wmf,ou=groups,dc=wikimedia,dc=org',
        ],
    }

    httpd::site { 'transparency.wikimedia.org':
        content => template('role/apache/sites/transparency.wikimedia.org.erb'),
    }

    httpd::site { 'transparency-private.wikimedia.org':
        content => template('role/apache/sites/transparency-private.wikimedia.org.erb'),
    }
}
