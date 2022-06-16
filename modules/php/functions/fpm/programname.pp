# SPDX-License-Identifier: Apache-2.0
function php::fpm::programname(Wmflib::Php_version $version) >> String {
    "php${version}-fpm"
}
