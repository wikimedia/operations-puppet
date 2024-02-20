<!-- SPDX-License-Identifier: Apache-2.0 -->
Thanos bucket query
====

Help operators analyze and query Thanos bucket information. In
particular to guide ad-hoc clean up of blocks before their configured
retention policy.

#### `import.py`

This script imports data extracted from a Thanos bucket, two kinds of
data (`--kind` option) are supported:

##### `blocks`

The default. Most information about a given block will be reported here
(e.g. time spans, block source, etc)

##### `sizes`

Import block sizes, size list requires walking the Thanos bucket and it
is performed by `block_sizes.py`.


#### `export.py`

The `import.py` counterpart, used to export data from a Thanos bucket.


#### Running

The following example commands can be used to import data locally for
further analysis. `python3` is required locally and `block_sizes.py`
must be available on `thanos host`.

```shell
ssh <thanos host> 'sudo thanos-bucket-query-export' | ./import.py
ssh <thanos host> 'sudo thanos-bucket-query-export --kind sizes' | ./import.py --kind sizes
```
