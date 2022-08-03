# @summary configure puppet ssl
# @param server_name the puppet server name
# @param ssldir tyhe ssl directory to use
class puppetmaster::ssl(
    Stdlib::Fqdn     $server_name = 'puppet',
    Stdlib::Unixpath $ssldir      = '/var/lib/puppet/server/ssl'
){

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
            "${ssldir}/crl",
        ]:
            ensure => directory;
        [
            "${ssldir}/private_keys",
            "${ssldir}/public_keys",
        ]:
            ensure => directory,
            mode   => '0750',;
    }

    exec { 'setup crl dir':
        require => File["${ssldir}/crl"],
        path    => '/usr/sbin:/usr/bin:/sbin:/bin',
        command => "ln -s ${ssldir}/ca/ca_crl.pem ${ssldir}/crl/$(openssl crl -in ${ssldir}/ca/ca_crl.pem -hash -noout).r0",
        onlyif  => "test ! -L ${ssldir}/crl/$(openssl crl -in ${ssldir}/ca/ca_crl.pem -hash -noout).r0",
    }
    # required so passanger app can start
    exec { 'generate puppet private key':
        command => '/usr/bin/puppet master',
        creates => "${ssldir}/private_keys/${server_name}.pem",
        require => File["${ssldir}/private_keys"],
        before  => Service['apache2'],
    }

}
