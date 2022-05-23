<!-- SPDX-License-Identifier: Apache-2.0 -->
## Toolforge Kubernetes Security Benchmarks

The files in this folder are intended to be use with the kube-bench tool found
here: https://github.com/aquasecurity/kube-bench

If you download the binary version of the latest release, you should be able to
copy the wmcs folder into the `cfg` folder in the tarball once it is unpacked.

From there, you can run `sudo ./kube-bench --benchmark wmcs -D cfg/ node` and
`sudo ./kube-bench --benchmark wmcs -D cfg/ master` as appropriate to check
security compliance of a worker node or control plane node, respectively.
