# SPDX-License-Identifier: Apache-2.0
function profile::base::certificates::get_trusted_ca_path() {
    include profile::base::certificates
    $profile::base::certificates::trusted_ca_path
}