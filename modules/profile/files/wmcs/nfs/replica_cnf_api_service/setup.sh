#!/bin/bash
# SPDX-License-Identifier: Apache-2.0

set -o errexit
set -o pipefail
set -o nounset

if [[ ! -f ./replica_cnf_api_service/views.py || ! -f ./requirements.txt ]]; then
    echo "This script requires ./replica_cnf_api_service/views.py and ./requirements.txt for a successful run"
    exit 1
fi

# create app folder if it doesn't exist
mkdir -p ~/replica_cnf_api_service

# copy configs and venv from old app to new app to be deployed
[[ -f $HOME/replica_cnf_api_service/instance/config.py ]] && mv ~/replica_cnf_api_service/instance/ ./instance/
[[ -d $HOME/replica_cnf_api_service/venv ]] && mv ~/replica_cnf_api_service/venv ./venv/

# remove old app
rm -rf ~/replica_cnf_api_service

# copy new app to old app location
cd ../ && mv ./replica_cnf_api_service ~/replica_cnf_api_service

cd ~/replica_cnf_api_service/

# create and activate venv if it doesn't already exists
python3 -m venv venv
. ./venv/bin/activate

pip install -r ./requirements.txt

# remove unnecessary files
rm .gitignore
rm -rf tests

# create temp directories for replica cnf
# create new config if it doesn't already exists
[[ ! -f /tmp/replica_cnf ]] && \
mkdir -p /tmp/replica_cnf/tools/shared/tools/project && \
mkdir -p /tmp/replica_cnf/misc/shared/paws/project/paws/userhomes && \
mkdir -p /tmp/replica_cnf/tools/shared/tools/home && \

# create new config if it doesn't already exists
[[ ! -f $HOME/replica_cnf_api_service/instance/config.py ]] && \
echo "SECRET_KEY = '$(python -c "import secrets; print(secrets.token_hex())")'" > ~/replica_cnf_api_service/instance/config.py && \
echo "TOOLS_REPLICA_CNF_PATH = '/tmp/replica_cnf/tools/shared/tools/project/'" >> ~/replica_cnf_api_service/instance/config.py && \
echo "PAWS_REPLICA_CNF_PATH = '/tmp/replica_cnf/misc/shared/paws/project/paws/userhomes/'" >> ~/replica_cnf_api_service/instance/config.py && \
echo "OTHERS_REPLICA_CNF_PATH = '/tmp/replica_cnf/tools/shared/tools/home/'" >> ~/replica_cnf_api_service/instance/config.py && \

# run with gunicorn
# exec ./venv/bin/gunicorn "replica_cnf_api_service.views:create_app()" --threads=3 --timeout 155 --bind 127.0.0.1:8000

# run with uwsgi
# uwsgi --master --http-socket :8000 --manage-script-name --mount /="replica_cnf_api_service.views:create_app()" --plugin python3

# uwsgi --master --http-socket :8000 --plugins python3 --module views:app --venv /home/raymond/Desktop/puppet/modules/profile/files/wmcs/nfs/replica_cnf_api_service/venv --chdir ./replica_cnf_api_service/


# reload the service to pick up new changes. This needs to be configured in systemd first
systemctl start replica_cnf_api_service
systemctl reload replica_cnf_api_service