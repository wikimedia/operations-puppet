# == Define: sslcert::ocsp_nginx
#
# This sets up OCSP stapling files for nginx usage with ssl_stapling_file.
#
# It will both create the OCSP stapling file initially (if not present) as
# well as define a singular cronjob on the host which updates all OCSP
# stapling files once an hour.
#
# The resource title must reflect the basename of the installed certificate
# (the same name used in e.g. install_certificate).
#
# === Parameters
#
# [*create_before*]
#   If defined, if this OCSP stapling file does not exist on-disk and needs to
#   be created for the first time, the Exec which creates it will have a "before"
#   metaparameter set to this value.
#
# === Example
#
#  sslcert::ocsp { 'pinkunicorn.wikimedia.org': create_before => Service['nginx']; }
#

define sslcert::ocsp_nginx(
    $create_before=[]
) {
    require sslcert
    include sslcert::ocsp::updater

    cert = "/etc/ssl/localcerts/${title}.crt"
    output = "/var/ssl/ocsp/${title}.ocsp"
    proxy = "webproxy.${::site}.wmnet:8080"

    exec { "${title}-create-ocsp":
        command => "/usr/local/sbin/update-ocsp -c $cert -o $output -p $proxy",
        creates => $output,
        require => Sslcert::Certificate[$title],
        before  => $create_before
    }
}

define sslcert::ocsp_nginx::updater(
) {
    require sslcert

    file { '/usr/local/sbin/update-ocsp':
        mode    => '0555',
        owner   => 'root',
        group   => 'root',
        source  => 'puppet:///modules/sslcert/update-ocsp',
    }

    file { '/usr/local/sbin/update-ocsp-all.sh':
        mode    => '0555',
        owner   => 'root',
        group   => 'root',
        source  => 'puppet:///modules/sslcert/update-ocsp-all.sh',
    }

    cron { 'update-ocsp-all':
        command => "/usr/local/bins/update-ocsp-all.sh webproxy.${::site}.wmnet:8080"
        minute  => fqdn_rand(60, 'sslcert::ocsp_nginx::updater'),
    }
}
