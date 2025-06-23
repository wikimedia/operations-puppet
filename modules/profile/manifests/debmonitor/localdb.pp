# SPDX-License-Identifier: Apache-2.0
# @summary This profile installs a local mysql DB for debmonitor-dev
class profile::debmonitor::localdb ()
{
    ensure_packages('mariadb-server')
}
