# Configuration info: https://wikitech.wikimedia.org/wiki/Trebuchet#Adding_a_new_repo
# Troubleshooting: https://wikitech.wikimedia.org/wiki/Trebuchet#Troubleshooting
class role::deployment::config {
    $repo_config = hiera_hash('role::deployment::repo_config')
}
