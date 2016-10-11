require 'master_manipulator'
test_name 'FM-4614 - Cxx - Install Puppet Enterprise'

# Init
step 'Install PE'
install_pe

step 'Disable Node Classifier'
disable_node_classifier(master)

step 'Disable Environment Caching'
disable_env_cache(master)

step 'Restart Puppet Server'
restart_puppet_server(master)
