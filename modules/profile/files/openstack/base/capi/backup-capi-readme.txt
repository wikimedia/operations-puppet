# SPDX-License-Identifier: Apache-2.0

This dir contains backups of the capi worker state.

Despite being kubernetes-like, k3s uses sqlite rather than etcd for state.
The dated tarballs in this directory are dumps of the sqlite data from

/var/lib/rancher/k3s/server/db/

This file may contain secrets; the associated rancher-k3s-server-token is
needed for k8s to access them.

- - -

To restore a capi worker node from a backup, you'll need two things from
this backup volume: a database dump (capi-backup-"$DATE".tgz) and
an associated token file (rancher-k3s-server-token-"$DATE").

First, build a new capi worker node from puppet following

https://wikitech.wikimedia.org/wiki/Portal:Cloud_VPS/Admin/Magnum_setup#capi_management_cluster

...then stop k3s and overwrite the fresh config with the backed up config (presumably
after mounting this volume on the new node).

$ kubectl drain `hostname` --delete-emptydir-data 
$ systemctl stop k3s
$ rm -rf /var/lib/rancher/k3s
$ tar -xvzaf <backup archive>.tgz -C /
$ cp <token file> /var/lib/rancher/k3s/server/token
$ systemctl start k3s

If this is on a fresh VM you will need to change the k8s api in /var/lib/magnum/.kube/config
which is in private puppet as modules/secret/secrets/openstack/<deployment>/magnum/capiservicek3s.yaml
