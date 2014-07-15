# Install Mediawiki-Vagrant puppet repo, manage manually from CLI
class role::labs::vagrant {
    include ::role::labs::lvm::srv
    include ::labs_vagrant

    # Mount secondary disk before applying labs_vagrant
    Labs_lvm::Volume <| |> -> Labs_vagrant <| |>
}
