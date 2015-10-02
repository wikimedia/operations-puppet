define tlsproxy::ocsp_stapler($certs) {
    require tlsproxy::ocsp_updater

    sslcert::ocsp::conf { $title:
        proxy => "webproxy.${::site}.wmnet:8080",
        certs => $certs,
    }
}
