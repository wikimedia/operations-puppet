# @summary configure cfssl api service
# @param conf_dir location of the configuration directory
class cfssl (
    Stdlib::Unixpath $conf_dir   = '/etc/cfssl',
    Stdlib::Unixpath $signer_dir = "${conf_dir}/signers",
    Array[String]    $packages   = ['golang-cfssl']
) {
    ensure_packages(['golang-cfssl'])
    $sql_dir = '/usr/local/share/cfssl'
    file{
        default:
            owner   => 'root',
            group   => 'root',
            require => Package[$packages];
        [$conf_dir, $sql_dir, $signer_dir]:
            ensure  => directory,
            purge   => true,
            recurse => true,
            mode    => '0550';
        "${sql_dir}/sqlite_initdb.sql":
            ensure => file,
            mode   => '0440',
            source => 'puppet:///modules/cfssl/sqlite_initdb.sql';
    }
}
