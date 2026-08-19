<!-- SPDX-License-Identifier: Apache-2.0 -->
# rkemper-kafka pontoon stack

This spins up a 3-broker kafka cluster, using `kafka-configurator`
to reconcile expected vs actual state, triggered upon puppet runs as well
as an every-30-minute timer job.

High-level steps:
bootstrap puppetserver VM -> push puppet branch
-> create + enroll remaining VMs -> let puppet converge

## One-time setup

```bash
# pontoonctl CLI
cd ~/wmf/operations/puppet/modules/pontoon/files
pipx install --editable '.[ctl]'

# environment (add to your shell profile)
export PONTOON_HOME=~/wmf/operations/puppet/modules/pontoon/files
export PONTOON_STACK=rkemper-kafka
```

Requires membership in the `kafka-infrastructure` Cloud VPS project:

In Horizon: `kafka-infrastructure` project -> `Identity` -> `Application Credentials`
-> create key and paste its id/secret into `~/.config/pontoon/cloudvps.yaml` (chmod 600)

In `~/.ssh/config`,
set `UserKnownHostsFile ~/.config/pontoon/ssh_known_hosts`
for `*.wmflabs` and `*.wikimedia.cloud`, placed above any global UserKnownHostsFile line
(ssh honors the first value it finds)

## Spin up

```bash
# (0) Check out the puppet patch
cd ~/wmf/operations/puppet
git review -d 1318976

# (1) Create the puppetserver VM and build it (~10 min)
pontoonctl bootstrap-stack --accept-ssh-key

# (2) Add the git remote it prints, then push your branch AS
#    'production' (the puppetserver only reads that branch name)
git remote add pontoon-rkemper-kafka \
  ssh://rk-kfk-puppet-01.kafka-infrastructure.eqiad1.wikimedia.cloud/~/puppet.git
git push -f pontoon-rkemper-kafka HEAD:production

# (3) Create and enroll every other VM in the rolemap (~5 min)
pontoonctl create-hosts --no-prompt

# (4) Grab fingerprints
pontoonctl ssh-keyscan

# (5) Enroll stragglers (this is idempotent)
pontoonctl enroll-hosts

# (6) Converge (will take 2 puppet runs to be fully healthy)
pontoonctl wait-puppet
```

In typical fashion, the first puppet run
will emit errors about stuff like `/usr/share/ca-certificates/wikimedia`
which the second puppet run will heal

## Verify

```bash
BROKER=rk-kfk-kafka-test-01.kafka-infrastructure.eqiad1.wikimedia.cloud
ssh $BROKER 'systemctl is-active kafka'                                                # active
ssh $BROKER 'sudo ss -tlnp | grep 9093'                                                # TLS listener
ssh $BROKER 'ls /etc/kafka/ssl/*.p12'                                                  # PKI keystore
ssh $BROKER 'kafka-broker-api-versions --bootstrap-server localhost:9092 | grep "id:"' # brokers registered
```

## Teardown

```bash
pontoonctl destroy-hosts --role kafka::test::broker --no-prompt
```
If spinning the stack back up, just start at step 2

## Tips

1. Brokers need the trixie image (see `specmap.yaml`):
   apt.wikimedia.org has no bookworm confluent-kafka 7.7 packages.
2. Run `ssh-keyscan` only after all hosts exist
3. After any spec change, push to the pontoon remote
   before running any pontoonctl commands, because while create-hosts
   reads your local spec files, enroll-hosts uses the remote branch,
   and a mismatch between the two will abort host enrollment
4. The puppetserver syncs your push into its live checkout
   (`/srv/git/operations/puppet`) via a hook that runs a plain
   `git checkout -B`, with no reset or clean. Force pushing
   your branch can leave untracked dirty files hanging around,
   which makes the next push fail. Just hard reset and re-push:
   `ssh rk-kfk-puppet-01... 'cd /srv/git/operations/puppet
   && sudo git reset --hard HEAD -q && sudo git clean -fdq'`
