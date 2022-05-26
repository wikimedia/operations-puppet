# SPDX-License-Identifier: Apache-2.0
class sbuild (
) {
    ensure_packages([
        'sbuild',
        'apt-cacher-ng',
        'schroot',
    ])
}
