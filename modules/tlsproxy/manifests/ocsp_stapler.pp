define tlsproxy::ocsp_stapler($certs) {
    require tlsproxy::ocsp_updater

    $proxy     = "webproxy.${::site}.wmnet:8080"
    $output    = "/var/cache/ocsp/${name}.ocsp"
    $cpfx      = '-c /etc/ssl/localcerts/'
    $csfx      = '.crt'
    $ocsp_args = join([$cpfx, join($certs, "$csfx $cpfx"), "$csfx -o $output"], '')
    # sorry for the horrible join, we need map() :P
    # for $name = 'x', $certs = ['C1', 'C2'], $ocsp_args should look like:
    # -c /etc/ssl/localcerts/C1.crt -c /etc/ssl/localcerts/C2.crt -o /var/cache/ocsp/x.ocsp

    # Initial creation on puppet run (ocsp_updater takes care after)
    exec { "${title}-create-ocsp":
        command => "/usr/local/sbin/update-ocsp -p $proxy $ocsp_args",
        creates => $output,
        before  => Service['nginx']
    }

    # Configuration file for ocsp_updater
    file { "/etc/ocsp_updater/${name}":
        owner => 'root',
        group => 'root',
        mode  => '0444',
        content => "${ocsp_args}\n";
    }

    # This should ideally only be for the ones in $certs, but that's a PITA...
    Sslcert::Std_cert<| |> -> Exec["${title}-create-ocsp"]
}
