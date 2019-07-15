# === Class contint::packages::apt
#
# Apt configuration needed for contint hosts
#
class contint::packages::apt {
    include ::apt::unattendedupgrades
}
