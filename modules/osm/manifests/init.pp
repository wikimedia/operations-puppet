# SPDX-License-Identifier: Apache-2.0
#

class osm {
    ensure_packages('osm2pgsql')
    ensure_packages('osmosis')
    ensure_packages('osmium-tool')
    ensure_packages('osmborder')
}
