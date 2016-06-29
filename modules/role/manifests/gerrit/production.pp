# modules/role/manifests/gerrit/production.pp
class role::gerrit::production {
        system::role { 'role::gerrit::production': description => 'Gerrit master' }
        include role::backup::host
        include base::firewall

        sslcert::certificate { $host: }

        monitoring::service { 'https':
            description   => 'HTTPS',
            check_command => "check_ssl_http!${::gerrit::host}",
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

        class { '::gerrit':
            smtp_host   => $::mail_smarthost[0],
            replication => {
                # If adding a new entry, remember to add the fingerprint to gerrit2's known_hosts
                'github' => {
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
