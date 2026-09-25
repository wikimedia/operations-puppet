# SPDX-License-Identifier: Apache-2.0

class profile::prometheus::promtool {

    #install prometheus package for 'promtool' command
    stdlib::ensure_packages(['prometheus'])

}
