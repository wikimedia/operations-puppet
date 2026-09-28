<!-- SPDX-License-Identifier: Apache-2.0 -->
# Lift Wing httpbb suites

httpbb suites that check Lift Wing (Machine Learning) production and staging
services. The suites live in `production/` and `staging/`, and are deployed to
`/srv/deployment/httpbb-tests/liftwing/` by `profile::httpbb`.

## Endpoints

Most suites go through the shared inference ingress. `recommendation-api-ng` is
the exception: it has its own discovery record and port.

Some services are deployed to production (eqiad) only and not to staging
(for example `embeddings`, `semantic-highlighting`, the Qwen LLMs, and the
policy-violation models), so their suites live in `production/` only.

## Per-suite settings

`service_availability.conf` holds all per-suite settings, so `run_all.sh` has no
service-specific logic. Each line is `<suite-basename> [<dc> ...] [key=value ...]`:

- `codfw` / `eqiad` restrict a suite to those datacentres. Some production isvcs
  are deployed to one datacentre only (for example the extra models in
  `llm/values-ml-serve-eqiad.yaml`, which have no codfw override in
  `deployment-charts`); `run_all.sh` skips such a suite in a datacentre where it
  is not deployed, instead of failing there.
- `port=<n>` overrides the https port (default `30443`).
- `host_production=<host>` / `host_staging=<host>` override the host for suites
  that do not use the shared inference ingress. `recommendation-api-ng` uses this
  because it has its own discovery record and port.

A suite that is not listed runs in both codfw and eqiad on the shared inference
ingress. When a service is added, removed, or moved between datacentres, or when
its host/port changes, update `service_availability.conf`.

| Environment | Shared ingress host          | Port  | recommendation-api-ng host                            | Port  | Datacentres  |
|-------------|------------------------------|-------|-------------------------------------------------------|-------|--------------|
| production  | `inference.svc.<dc>.wmnet`   | 30443 | `recommendation-api-ng.discovery.wmnet`               | 31443 | codfw, eqiad |
| staging     | `inference-staging.svc.codfw.wmnet` | 30443 | `recommendation-api-ng.k8s-ml-staging.discovery.wmnet` | 31443 | codfw only   |

## Run one suite

Run a single suite against the shared ingress from a deployment server (or a
cumin host):

```sh
httpbb /srv/deployment/httpbb-tests/liftwing/production/test_revertrisk.yaml \
  --host inference.svc.codfw.wmnet --https_port 30443
```

`recommendation-api-ng` needs its own host and port:

```sh
httpbb /srv/deployment/httpbb-tests/liftwing/production/test_recommendation-api-ng.yaml \
  --host recommendation-api-ng.discovery.wmnet --https_port 31443
```

## Run all suites

`run_all.sh` runs every Lift Wing suite for one environment, one suite at a
time, and reports the result per suite. It is not deployed by Puppet; copy it to
a deployment or cumin host (or point `HTTPBB_LIFTWING_DIR` at a local suite tree)
and run it from there.

```sh
./run_all.sh                    # production, codfw (defaults)
./run_all.sh production eqiad   # production, eqiad
./run_all.sh staging            # staging, codfw
```

Arguments:

- First argument: environment, `production` (default) or `staging`.
- Second argument: datacentre, `codfw` (default) or `eqiad`. Staging is codfw
  only, so the datacentre argument is ignored for staging.

By default the script reads the suites from
`/srv/deployment/httpbb-tests/liftwing`. Set `HTTPBB_LIFTWING_DIR` to use a
different suite tree, for example a local copy:

```sh
HTTPBB_LIFTWING_DIR=/tmp/liftwing ./run_all.sh production eqiad
```

The script prints one `PASS`/`FAIL` line per suite, shows the full httpbb output
under a failed suite, and exits non-zero if any suite fails.

```
== Lift Wing production suites ==
PASS  test_article-descriptions
PASS  test_llm
PASS  test_revertrisk
...
PASS  test_recommendation-api-ng
== Done: 27 passed, 0 failed ==
```
