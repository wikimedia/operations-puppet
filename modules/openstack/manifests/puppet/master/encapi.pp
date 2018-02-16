class openstack::puppet::master::encapi(
    $horizon_host,
    $mysql_host,
    $mysql_db,
    $mysql_username,
    $statsd_host,
    $statsd_prefix,
    $mysql_password,
    $labs_instance_range,
    $puppetmasters,
    $labweb_hosts,
) {
    $horizon_host_ip = ipresolve($horizon_host, 4)

    require_package('python3-pymysql',
                    'python3-statsd',
                    'python3-flask',
                    'python3-yaml')

    if os_version('debian >= jessie') {
        require_package('python-flask',
                        'python-pymysql',
                        'python-statsd',
                        'python-yaml')
    }


    file { '/usr/local/lib/python3.4/dist-packages/labspuppetbackend.py':
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/openstack/puppet/master/encapi/labspuppetbackend.py',
    }

    # uwsgi security rules:
    #
    # Each of these is a pair of sequential rules.  They have to be adjacent
    #  and Puppet can't be trusted to insert them in the correct order.
    #
    # The first rule says "If the request is from a horizon host, skip the next rule."
    #
    # The second rule says "If this is a post, throw a 403"
    #
    # The sum effect is to allow POSTs only from horizon.
    #
    # I look forward to someone pointing out a better way to do this!

    $labweb_rules = $labweb_hosts.map |$host| { sprintf("^%s\$ continue:\nroute-if=equal:\${REQUEST_METHOD};POST break:403 Forbidden", ipresolve([<%= host %>, 4])) }
    $labweb_rules_v6 = $labweb_hosts.map |$host| { sprintf("^%s\$ continue:\nroute-if=equal:\${REQUEST_METHOD};POST break:403 Forbidden", ipresolve([<%= host %>, 6])) }
    $horizon_rule = "^${horizon_host_ip}\$ continue:\nroute-if=equal:\${REQUEST_METHOD};POST break:403 Forbidden"

    uwsgi::app { 'labspuppetbackend':
        settings  => {
            uwsgi => {
                plugins             => 'python3',
                'wsgi-file'         => '/usr/local/lib/python3.4/dist-packages/labspuppetbackend.py',
                callable            => 'app',
                master              => true,
                http-socket         => '0.0.0.0:8101',
                env                 => [
                    "MYSQL_HOST=${mysql_host}",
                    "MYSQL_DB=${mysql_db}",
                    "MYSQL_USERNAME=${mysql_username}",
                    "MYSQL_PASSWORD=${mysql_password}",
                    "STATSD_HOST=${statsd_host}",
                    "STATSD_PREFIX=${statsd_prefix}",
                ],
                'route-remote-addr' => flatten($horizon_rule, $labweb_rules, $labweb_rules_v6),
            },
        },

        subscribe => File['/usr/local/lib/python3.4/dist-packages/labspuppetbackend.py'],
    }

    # This is a GET-only front end that sits on port 8100.  We can
    #  open this up to the public even though the actual API has no
    #  auth protections.
    nginx::site { 'labspuppetbackendgetter':
        content => template('openstack/puppet/master/encapi/labspuppetbackendgetter.conf.erb'),
    }
}
