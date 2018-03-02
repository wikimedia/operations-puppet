# Common ferm resource for database access. The actual databases are listening on 3306
# and are initially limited to the internal network. More specialised classes
# could grant additional access to other hosts

define profile::mariadb::ferm (
    $port = '3306',
    $labweb_hosts = hiera('profile::openstack::main::labweb_hosts'),
) {
    if $port == '3306' {
        $rule_name = 'mariadb_internal'
    } else {
        $rule_name = "${title}_mariadb_internal"
    }
    ferm::service{ $rule_name:
        proto   => 'tcp',
        port    => $port,
        notrack => true,
        srange  => '$INTERNAL',
    }

    # labweb hosts need db access to use swift for wikitech images
    $labweb_ips = inline_template("@resolve((<%= @labweb_hosts.join(' ') %>))")
    ferm::service{ 'labweb':
        proto   => 'tcp',
        port    => '3306',
        notrack => true,
        srange  => $labweb_ips,
    }

    # auxiliary port. FIXME for non-standard ports
    if $port == '3306' {
        # for DBA purposes
        ferm::rule { 'mariadb_dba':
            rule => 'saddr ($MYSQL_ROOT_CLIENTS) proto tcp dport (3307) ACCEPT;',
        }
    }
}
