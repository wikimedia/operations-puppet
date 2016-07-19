# === Class puppetmaster::web_test
#
# Installs a virtualhost (and the corresponding certificate) for
# an alternative puppetmaster frontend which can have different workers than
# the standard one.
#
class puppetmaster::web_test ($server_name, $workers = {}) {
    Class['::puppetmaster'] -> Class['::puppetmaster::web_test']
    $ssl_settings = ssl_ciphersuite('apache', 'compat')
    $ssldir = $::puppetmaster::ssl::ssldir

    # Have puppet generate the certificate for this virtualhost
    exec { 'generate hostcert':
        require => File["${ssldir}/certs"],
        command => "/usr/bin/puppet cert generate ${server_name}",
        creates => "${ssldir}/certs/${server_name}.pem";
    }

    apache::site { 'puppetmaster-test':
        content  => template('puppetmaster/puppetmaster-test.erb'),
        priority => 90,
        require  => Exec['generate hostcert'],
    }
}
