# == Class statistics::web
# Common things needed for a statistics webserver node.
# This should be included if you want to include any
# sites in statistics::sites
class statistics::web {
    Class['::statistics'] -> Class['::statistics::web']

    $ssl_settings = ssl_ciphersuite('apache-2.2', 'compat', '365')

    # make sure /var/log/apache2 is readable by wikidevs for debugging.
    # This won't make the actual log files readable, only the directory.
    # Individual log files can be created and made readable by
    # classes that manage individual sites.
    file { '/var/log/apache2':
        ensure => 'directory',
        owner  => 'root',
        group  => 'wikidev',
        mode   => '0750',
    }

    include ::apache::mod::rewrite
    include ::apache::mod::proxy
    include ::apache::mod::proxy_http
    include ::apache::mod::headers
}
