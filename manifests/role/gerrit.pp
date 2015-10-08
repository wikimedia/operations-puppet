# manifests/role/gerrit.pp

class role::gerrit {
    class production {
        system::role { 'role::gerrit::production': description => 'Gerrit master' }
        include role::backup::host
        include base::firewall

        sslcert::certificate { 'gerrit.wikimedia.org': }

        monitoring::service { 'https':
            description   => 'HTTPS',
            check_command => 'check_ssl_http!gerrit.wikimedia.org',
        }

        backup::set { 'var-lib-gerrit2-review_site-git': }

        interface::ip { 'role::gerrit::production_ipv4':
            interface => 'eth0',
            address   => '208.80.154.81',
            prefixlen => '32',
        }
        interface::ip { 'role::gerrit::production_ipv6':
            interface => 'eth0',
            address   => '2620:0:861:3:208:80:154:81',
            prefixlen => '128',
        }

        ferm::service { 'gerrit_ssh':
            proto => 'tcp',
            port  => '29418',
        }

        ferm::service { 'gerrit_http':
            proto => 'tcp',
            port  => 'http',
        }

        ferm::service { 'gerrit_https':
            proto => 'tcp',
            port  => 'https',
        }

        $replication_basic_push_refs = [
            '+refs/heads/*:refs/heads/*',
            '+refs/tags/*:refs/tags/*',
        ]

        class { "gerrit::instance":
            db_host      => 'm2-master.eqiad.wmnet',
            host         => 'gerrit.wikimedia.org',
            ssh_key      => 'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAxOlshfr3UaPr8gQ8UVskxHAGG9xb55xDyfqlK7vsAs/p+OXpRB4KZOxHWqI40FpHhW+rFVA0Ugk7vBK13oKCB435TJlHYTJR62qQNb2DVxi5rtvZ7DPnRRlAvdGpRft9JsoWdgsXNqRkkStbkA5cqotvVHDYAgzBnHxWPM8REokQVqil6S/yHkIGtXO5J7F6I1OvYCnG1d1GLT5nDt+ZeyacLpZAhrBlyFD6pCwDUhg4+H4O3HGwtoh5418U4cvzRgYOQQXsU2WW5nBQHE9LXVLoL6UeMYY4yMtaNw207zN6kXcMFKyTuF5qlF5whC7cmM4elhAO2snwIw4C3EyQgw== gerrit@production',
            ssl_cert     => 'gerrit.wikimedia.org',
            ssl_cert_key => 'gerrit.wikimedia.org',
            smtp_host    => $::mail_smarthost[0],
            replication  => {
                # If adding a new entry, remember to add the fingerprint to gerrit2's known_hosts

                'gitblit'        => {
                    # Note: This is in single quotes on purpose. ${name} is not
                    # expected to be expanded by puppet but rather by gerrit
                    #
                    # lint:ignore:single_quote_string_with_variables
                    'url'       => 'gerritslave@antimony.wikimedia.org:/var/lib/git/${name}.git',
                    # lint:endignore
                    'threads'   => '4',
                    'authGroup' => 'mediawiki-replication',
                    'push'      => '+refs/*:refs/*',
                    'mirror'    => true,
                },
                'github'         => {
                    # Note: This is in single quotes on purpose. ${name} is not
                    # expected to be expanded by puppet but rather by gerrit
                    #
                    # lint:ignore:single_quote_string_with_variables
                    'url'             => 'git@github.com:wikimedia/${name}',
                    # lint:endignore
                    'threads'         => '4',
                    'authGroup'       => 'mediawiki-replication',
                    'push'            => $replication_basic_push_refs,
                    'remoteNameStyle' => 'dash',
                    'mirror'          => true,
                },
                # Do not add custom mirrors for GitHub here!
                # Instead let the default replication happen and perform the rename
                # on GitHub. This to avoid having duplicate repos on GitHub with
                # their own Stars, Pull requests, Issues etc. as well as duplicate
                # results in Code Search. See T70054.
            }
        }
    }

    # Include this role on *any* production host that wants to
    # receive gerrit replication
    class production::replicationdest {
        system::role { 'role::gerrit::replicationdest': description => 'Destination for gerrit replication' }

        class { 'gerrit::replicationdest':
            ssh_key => 'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAxOlshfr3UaPr8gQ8UVskxHAGG9xb55xDyfqlK7vsAs/p+OXpRB4KZOxHWqI40FpHhW+rFVA0Ugk7vBK13oKCB435TJlHYTJR62qQNb2DVxi5rtvZ7DPnRRlAvdGpRft9JsoWdgsXNqRkkStbkA5cqotvVHDYAgzBnHxWPM8REokQVqil6S/yHkIGtXO5J7F6I1OvYCnG1d1GLT5nDt+ZeyacLpZAhrBlyFD6pCwDUhg4+H4O3HGwtoh5418U4cvzRgYOQQXsU2WW5nBQHE9LXVLoL6UeMYY4yMtaNw207zN6kXcMFKyTuF5qlF5whC7cmM4elhAO2snwIw4C3EyQgw== gerrit@production',
        }
    }
}
