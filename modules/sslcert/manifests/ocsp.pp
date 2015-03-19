# == Define: sslcert::ocsp
#
# This creates a cronjob that creates/refreshes an ocsp stapling file (for use
# with nginx oscp_stapling_file) once an hour for a given certificate with a
# filename of the form /var/ssl/ocsp/${certname}.ocsp.  It also creates the
# file immediately if it doesn't already exist.  The hourly time offsets are
# randomized based on both the host fqdn and the certname.
#
# === Examples
#
#  sslcert::ocsp { 'pinkunicorn.wikimedia.org': }
#

define sslcert::ocsp(
) {
    require sslcert

    $create_cmd = "/usr/local/sbin/update-ocsp.sh ${title}"

    exec { "${title}_create_ocsp":
        command => $create_cmd,
        creates => "/var/ssl/ocsp/${title}.ocsp",
        before => Cron["${title}_update_ocsp"],
        require => [
            File['/usr/local/sbin/update-ocsp.sh'],
            Sslcert::Certificate[$title],
        ],
    }

    cron { "${title}_update_ocsp":
        command => $create_cmd,
        minute  => fqdn_rand(60, $title),
    }
}
