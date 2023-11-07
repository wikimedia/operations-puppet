# SPDX-License-Identifier: Apache-2.0
# special VM for stewards (T344164)
class profile::stewards (
){
    ensure_packages(['python3-click', 'python-requests-oauthlib'])
}
