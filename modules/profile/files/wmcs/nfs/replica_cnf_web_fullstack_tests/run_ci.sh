#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
# Ugly hack to be able to run inside a docker container

set -o errexit
set -o nounset
set -o pipefail

CURFILE="$(realpath "$0")"
CURDIR="${CURFILE%/*}"
FAKE_BINDIR="/tmp/fakebins"
cd "$CURDIR"
SERVER_PID=0
ENVVARS_SERVER_PID=0


cleanup() {
    if [[ "$SERVER_PID" != "0" ]]; then
        kill -9 "$SERVER_PID"
    fi
    if [[ "$ENVVARS_SERVER_PID" != "0" ]]; then
        kill -9 "$ENVVARS_SERVER_PID"
    fi
}

trap cleanup EXIT


create_fake_kubeconfig(){
    cat <<EOK >/tmp/dummy_kubeconfig
current-context: dummycontext
contexts: 
    - name: dummycontext
      context:
        cluster: dummycluster
        user: dummyuser
        namespace: dummynamespace
clusters:
    - name: dummycluster
      cluster:
        server: dummyserver
users:
    - name: dummyuser
      user:
        token: "dummy token"
servers:
    - name: dummyserver
      server: {}
EOK
}

prepare_fake_env() {
    create_fake_kubeconfig

    # this is needed as inside the docker image we don't have sudo
    # nor chattr (as only root can do it)
    mkdir -p "$FAKE_BINDIR"
    cat >"$FAKE_BINDIR/sudo" <<EOS
#!/bin/bash
# skip the --preserve-env param
if [[ "\$1" =~ ^--preserve-env ]]; then
    shift
fi
"\$@"
EOS
    chmod +x "$FAKE_BINDIR/sudo"

    cat >"$FAKE_BINDIR/chattr" <<EOS
#!/bin/bash
# In ci we don't have root, so we can't chattr, just do nothing
exit 0
EOS
    chmod +x "$FAKE_BINDIR/chattr"

    # Inject the path to the scripts
    for script in write read delete; do
        cat >"$FAKE_BINDIR/${script}_replica_cnf.sh" <<EOS
    #!/bin/bash
    export PATH=$FAKE_BINDIR:$PATH
    $CURDIR/../replica_cnf_api_service/${script}_replica_cnf.sh "\$@"
EOS
        chmod +x "$FAKE_BINDIR/${script}_replica_cnf.sh"
    done

    # inject the path for bats
    export PATH=$FAKE_BINDIR:$PATH
}


start_server() {
    PATH=$FAKE_BINDIR:$PATH \
    CONF_FILE=ci_config.yaml \
    PORT=8081 \
    PYTHONPATH=$PWD/../replica_cnf_api_service \
        python ../replica_cnf_api_service/replica_cnf_api_service/views.py 2>&1 &
    SERVER_PID=$!
}

start_fake_toolforge_envvars() {
    python $PWD/../replica_cnf_api_service/tests/mock_envvars.py 2>&1 &
    ENVVARS_SERVER_PID=$!
    # wait for the server to start
    max_wait=0
    while ! curl --silent http://127.0.0.1:8081/healthz >/dev/null; do
        sleep 0.1
        max_wait=$((max_wait + 1))
        if [[ $max_wait -ge 100 ]]; then
            echo "Timed out to start the mocked envvars service."
            exit 1
        fi
    done
    sleep 2
}

run_tests() {
    CONF_FILE=ci_config.yaml \
    PROJECT=localtest  \
    TOOL_NAME=tools.$(id -nu) \
    USER_ID=$(id -u) \
    BASE_URL="http://127.0.0.1:8081/v1" \
    TERM=xterm-256color \
    bats_core_pkg --timing --print-output-on-failure --verbose-run .
}


main() {
    prepare_fake_env
    start_server
    start_fake_toolforge_envvars
    run_tests
}


main "$@"