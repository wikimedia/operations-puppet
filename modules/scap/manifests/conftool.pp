# === Class scap::conftool
#
# Adds conftool scripts and credentials for the deploy-service user, used by
# scap3. This will allow scap3 to call "pool", "depool" and so on
#
class scap::conftool {
    include ::conftool::scripts

    ::conftool::credentials { 'deploy-service':
        home => '/var/lib/deploy-service',
    }
}
