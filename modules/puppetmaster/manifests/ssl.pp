
class puppetmaster::ssl(
            $server_name='puppet',
) {
    $ssldir = '/var/lib/puppet/server/ssl'

    # TODO: Hack to make class pass tests
    if defined(Package['puppetmaster']) {
        $before = Package['puppetmaster']
    } else {
        $before = undef
    }

    # Move the puppetmaster's SSL files to a separate directory from the client
    file {
        [ '/var/lib/puppet/server',
            $ssldir,
        ]:
            ensure => directory,
            owner  => 'puppet',
            group  => 'root',
            mode   => '0771',
            before => $before;
        [
            "${ssldir}/ca",
            "${ssldir}/certificate_requests",
            "${ssldir}/certs",
            "${ssldir}/private",
            "${ssldir}/private_keys",
            "${ssldir}/public_keys",
            "${ssldir}/crl",
        ]:
            ensure => directory;
    }

    exec { 'setup crl dir':
        require => File["${ssldir}/crl"],
        path    => '/usr/sbin:/usr/bin:/sbin:/bin',
        command => "ln -s ${ssldir}/ca/ca_crl.pem ${ssldir}/crl/$(openssl crl -in ${ssldir}/ca/ca_crl.pem -hash -noout).r0",
        onlyif  => "test ! -L ${ssldir}/crl/$(openssl crl -in ${ssldir}/ca/ca_crl.pem -hash -noout).r0",
    }
}
