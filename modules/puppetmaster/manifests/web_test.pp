# === Class puppetmaster::web_test
#
# Installs a virtualhost (and the corresponding certificate) for
# an alternative puppetmaster frontend which can have different workers than
# the standard one.
#
class puppetmaster::web_test ($server_name, $workers = {}, $alt_names=[]) {
    Class['::puppetmaster'] -> Class['::puppetmaster::web_test']
    $ssl_settings = ssl_ciphersuite('apache', 'compat')
    $ssldir = $::puppetmaster::ssl::ssldir

    $alt_names_list = join(sort($alt_names), ',')
    # Have puppet generate the certificate for this virtualhost
    # BEWARE: SSL key length cannot be controlled here
    exec { 'generate hostcert':
        require => File["${ssldir}/certs"],
        command => "/usr/bin/puppet cert generate ${server_name} --dns_alt_names ${alt_names_list}",
        creates => "${ssldir}/certs/${server_name}.pem";
    }

    apache::site { 'puppetmaster-test':
        content  => template('puppetmaster/puppetmaster-test.erb'),
        priority => 90,
        require  => Exec['generate hostcert'],
    }
}
