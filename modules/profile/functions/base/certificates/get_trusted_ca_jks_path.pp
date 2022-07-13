# SPDX-License-Identifier: Apache-2.0
function profile::base::certificates::get_trusted_ca_jks_path() {
    include profile::base::certificates
    $profile::base::certificates::jks_truststore_path
}