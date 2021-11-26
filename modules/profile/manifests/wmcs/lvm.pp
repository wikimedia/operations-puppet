# profile for using the old labs_lvm modules
class profile::wmcs::lvm (
    Stdlib::Unixpath $disk      = lookup('profile::wmcs::lvm::disk', {'default_value' => '/dev/sdb'}),
    Boolean          $ephemeral = lookup('profile::wmcs::lvm::ephemeral', {'default_value' => true}),
) {
    class { 'labs_lvm':
        disk      => $disk,
        ephemeral => $ephemeral,
    }
}
