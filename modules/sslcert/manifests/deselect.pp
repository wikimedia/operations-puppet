# SPDX-License-Identifier: Apache-2.0
# @summary Removes a certificate from ca-certificates.conf
define sslcert::deselect (
    String[1] $certificate = $title,
) {
    include sslcert

    file_line { "deselect-${title}":
        path               => '/etc/ca-certificates.conf',
        match              => "^!?${certificate.regexpescape}$",
        line               => "!${certificate}",
        append_on_no_match => false,
        # These are in the sslcert init.pp:
        notify             => Exec['update-ca-certificates'],
        require            => Package['ca-certificates'],
    }
}
