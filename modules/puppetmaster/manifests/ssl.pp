
class puppetmaster::ssl(
    String       $cert_secret_path = 'puppetmaster',
){

    include puppetmaster
    $server_name = $puppetmaster::server_name
    $master_ssldir = $facts['puppet_config']['master']['ssldir']
    # Move the puppetmaster's SSL files to a separate directory from the client
    file {
        ['/var/lib/puppet/server', $master_ssldir]:
            ensure => directory,
            owner  => 'puppet',
            group  => 'root',
            mode   => '0771';
        [
            "${master_ssldir}/ca",
            "${master_ssldir}/certificate_requests",
            "${master_ssldir}/certs",
            "${master_ssldir}/private",
            "${master_ssldir}/private_keys",
            "${master_ssldir}/public_keys",
            "${master_ssldir}/crl",
        ]:
            ensure => directory;
    }
    if $server_name != $facts['fqdn'] {
        file {
            default:
                owner     => 'puppet',
                group     => 'puppet',
                mode      => '0640',
                show_diff => false;
            "${master_ssldir}/certs/${server_name}.pem":
                content   => secret("${cert_secret_path}/${server_name}_pubkey.pem");
            "${master_ssldir}/private_keys/${server_name}.pem":
                content   => secret("${cert_secret_path}/${server_name}_privkey.pem");
        }
    }

    exec { 'setup crl dir':
        require => File["${master_ssldir}/crl"],
        path    => '/usr/sbin:/usr/bin:/sbin:/bin',
        command => "ln -s ${master_ssldir}/ca/ca_crl.pem ${master_ssldir}/crl/$(openssl crl -in ${master_ssldir}/ca/ca_crl.pem -hash -noout).r0",
        onlyif  => "test ! -L ${master_ssldir}/crl/$(openssl crl -in ${master_ssldir}/ca/ca_crl.pem -hash -noout).r0",
    }
}
