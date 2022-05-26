# SPDX-License-Identifier: Apache-2.0
# @summary install sqlite
# @param ensure ensurable parameter
# @param default_db_path default location for dbs
# @param package package name to install
# @param sqlite_cmd sqlite command to use
class sqlite (
    Wmflib::Ensure            $ensure          = 'present',
    Stdlib::Unixpath          $default_db_path = '/var/lib/sqlite',
    Enum['sqlite', 'sqlite3'] $sqlite_cmd      = 'sqlite3',
    Enum['sqlite', 'sqlite3'] $package         = $sqlite_cmd,
){
    ensure_packages($package, {'ensure' => $ensure })
    ensure_resource('file', $default_db_path, {'ensure' => stdlib::ensure($ensure, 'directory')})
}
