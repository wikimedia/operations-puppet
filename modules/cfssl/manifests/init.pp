# SPDX-License-Identifier: Apache-2.0
# @summary configure cfssl api service
# @param conf_dir location of the configuration directory
class cfssl (
    Stdlib::Unixpath $conf_dir    = '/etc/cfssl',
    Stdlib::Unixpath $signer_dir  = "${conf_dir}/signers",
    Stdlib::Unixpath $csr_dir     = "${conf_dir}/csr",
    Stdlib::Unixpath $ocsp_dir    = "${conf_dir}/ocsp",
    Stdlib::Unixpath $ssl_dir     = "${conf_dir}/ssl",
    Stdlib::Unixpath $bundles_dir = "${conf_dir}/ssl/bundles",
    Array[String]    $packages    = ['golang-cfssl']
) {
    ensure_packages(['golang-cfssl'])
    $sql_dir = '/usr/local/share/cfssl'
    file{
        default:
            owner   => 'root',
            group   => 'root',
            require => Package[$packages];
        [$conf_dir, $sql_dir, $signer_dir, $csr_dir, $ssl_dir]:
            ensure  => directory,
            purge   => true,
            recurse => true,
            force   => true,
            mode    => '0550';
        [$ocsp_dir, $bundles_dir]:
            ensure => directory,
            mode   => '0550';
        "${sql_dir}/sqlite_initdb.sql":
            ensure => file,
            mode   => '0440',
            source => 'puppet:///modules/cfssl/sqlite_initdb.sql';
        "${sql_dir}/mysql_initdb.sql":
            ensure => file,
            mode   => '0440',
            source => 'puppet:///modules/cfssl/mysql_initdb.sql';
    }
}
