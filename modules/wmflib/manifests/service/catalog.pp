# SPDX-License-Identifier: Apache-2.0
# @summary class to allow us to load yaml data reducing the need to do so for every function call
class wmflib::service::catalog {
    $pools       = lookup('service::catalog', {'default_value' => {}})  # lint:ignore:wmf_styleguide
    wmflib::service::validate($pools)
    $pools_lvs   = $pools.filter |$service, $data| { has_key($data, 'lvs') }
}
