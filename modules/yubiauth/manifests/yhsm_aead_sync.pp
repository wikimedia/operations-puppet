# This sets up an rsync server, which can be used to synchronise the AEADs between the Yubico authentication servers.
class yubiauth::yhsm_aead_sync(
    $sync_allowed = '127.0.0.1',
) {
    include rsync::server

    rsync::server::module { 'aead_sync':
        path        => '/var/cache/yubikey-ksm/aeads',
        read_only   => 'yes',
        hosts_allow => $sync_allowed,
        auto_ferm   => true,
    }
}
