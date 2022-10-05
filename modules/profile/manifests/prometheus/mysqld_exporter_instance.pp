# SPDX-License-Identifier: Apache-2.0
define profile::prometheus::mysqld_exporter_instance (
    $socket = "/run/mysqld/mysqld.${title}.sock",
    $port = 13306,
    ) {

    prometheus::mysqld_exporter::instance { $title:
        client_socket  => $socket,
        listen_address => ":${port}",
    }
}
