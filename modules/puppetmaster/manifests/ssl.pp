class puppetmaster::ssl(
            $server_name,
            $ca
) {
    $ssldir = '/var/lib/puppet/server/ssl'

    # Move the puppetmaster's SSL files to a separate directory from the client
    file {
        [ '/var/lib/puppet/server',
            $ssldir
        ]:
            ensure  => directory,
            owner   => 'puppet',
            group   => 'root',
            mode    => '0771',
    }
    file {
        [
            "${ssldir}/ca",
            "${ssldir}/certificate_requests",
            "${ssldir}/certs",
            "${ssldir}/private",
            "${ssldir}/private_keys",
            "${ssldir}/public_keys",
            "${ssldir}/crl"
        ]:
            ensure => directory;
    }

    if $ca != 'false' {
        exec { 'generate hostcert':
            require => File["${ssldir}/certs"],
            command => "/usr/bin/puppet cert generate ${server_name}",
            creates => "${ssldir}/certs/${server_name}.pem";
        }
    }

    exec { 'setup crl dir':
        require => File["${ssldir}/crl"],
        path    => '/usr/sbin:/usr/bin:/sbin:/bin',
        command => "ln -s ${ssldir}/ca/ca_crl.pem ${ssldir}/crl/$(openssl crl -in ${ssldir}/ca/ca_crl.pem -hash -noout).0",
        onlyif  => "test ! -L ${ssldir}/crl/$(openssl crl -in ${ssldir}/ca/ca_crl.pem -hash -noout).0"
    }
}
