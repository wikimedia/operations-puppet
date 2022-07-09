# SPDX-License-Identifier: Apache-2.0
# @summary function to check if puppetdb is available
function wmflib::have_puppetdb >> Boolean {
    # TODO: there should be a better way to do this
    $settings::storeconfigs == true and $settings::storeconfigs_backend == 'puppetdb'
}
