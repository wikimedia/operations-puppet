#!/bin/bash
set -e
function usage {
    cat <<EOF
usage: $0 [--apply] <urls-file> [<environment>]

  Small helper script for automating apache configuration changes rollout.
  urls-file    File containing urls to test. Some standard ones are provided
               in /usr/local/share/apache-tests
  environment  either "prod" (the default) or "beta"
  --apply      Tells the script to apply the puppet change after the test, not
               just to reenable puppet
EOF
    exit 1
}

# ARGS mangling
if [ $# -lt 1 ]; then
    usage
fi
# Default variables
apply="no"
if [ "$1" == "--apply" ]; then
    shift
    apply="yes"
    if [ $# -lt 1 ]; then
        usage
    fi
fi
test_file=$1
environment=${2:-prod}
canary=${CANARY:-"mwdebug1001.eqiad.wmnet"}
control=${CONTROL:-"mw1266.eqiad.wmnet"}
puppetmaster=$(sudo puppet config print --section agent ca_server)
targets="R:Class ~ '(?i)mediawiki(_exp)?::web::${environment}_sites'"


# Check the canary and control servers are in good health
apache-fast-test "$test_file" "$canary" "$control"
# Disable puppet everywhere
echo "Now we will disable puppet on all servers with the shared apache configuration."
sudo cumin "$targets" "disable-puppet 'apache change ongoing --${USER}'"
# Merge the puppet change you already submitted
echo "Puppet is disabled everywhere. Should we merge the puppet change?"
sudo cumin "$puppetmaster" "TERM=$TERM puppet merge -y"
# Run puppet on the canary
echo "Ok to run puppet on the canary host to apply the apache change?"
sudo cumin "$canary" "run-puppet-agent -e 'apache change ongoing --${USER}'"
# Re-check the sites
echo "Checking sites again"
apache-fast-test "$test_file" "$canary" "$control"
echo "Things seem OK from our test."
if [ "$apply" == "yes" ]; then
    # Run puppet everywhere, 5 hosts at a time, which is very conservative.
    echo "Should we run apply the puppet change on all servers?"
    sudo cumin -b 30 -p 99 "$targets" "run-puppet-agent -e 'apache change ongoing --${USER}'"
else
    # Enable puppet everywhere when you feel comfortable
    echo  "Should puppet be reenabled on all servers?"
    sudo cumin "$targets" "enable-puppet 'apache change ongoing --${USER}'"
fi
