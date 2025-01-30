#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# This script is used to publish the kubernetes service account certificate to etcd
# in order for other kubernetes apiservers to pull and use it to validate service account tokens
# issued by this apiserver.
#
# The service account certificate is published to etcd by its SHA1 fingerprint and a generic
# prefix provided as argument to this script.
#
# The script also cleans up expired certificates from etcd by iterating over all of them, checking
# if they are about to expire within the next second and deleting them if they are.

set -eu
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <etcd_key_prefix> <sa_cert_path>"
    exit 1
fi

ETCD_PREFIX="$1"
SA_CERT_PATH="$2"

if [ -z "$ETCD_PREFIX" ]; then
    echo "Error: The etcd key prefix may not be empty"
    exit 2
fi

if [ ! -r "$SA_CERT_PATH" ]; then
    echo "Error: The file '$SA_CERT_PATH' does not exist or is not readable"
    exit 2
fi

etcdctl="$(which etcdctl)"
openssl="$(which openssl)"
export ETCDCTL_API=3
export ETCDCTL_ENDPOINTS="${ETCDCTL_ENDPOINTS:-https://$(hostname -f):2379}"

# Get the SHA1 fingerprint of the sa cert
# openssl output looks something like this:
# SHA1 Fingerprint=E0:F6:46:1E:A8:2F:47:77:8A:30:23:2B:64:6B:8D:49:2C:3A:FC:0D
sa_cert_fingerprint="$($openssl x509 -in "$SA_CERT_PATH" -noout -fingerprint | sed 's/.*=//')"
if [ -z "$sa_cert_fingerprint" ]; then
    echo "Error: Could not extract the fingerprint from the sa cert"
    exit 3
fi
etcd_key="$ETCD_PREFIX/$sa_cert_fingerprint"

# Clean up expired certificates
keys_to_delete=()
keys_to_keep=0
# Fetch the certificate from etcd and check if it expires within the next second
# etcdctl get returns a list of keys with a trailing empty lines, these need to be stripped
for key in $($etcdctl get --prefix "$ETCD_PREFIX" --keys-only | sed '/^$/d'); do
  if $etcdctl get "$key" | $openssl x509 -in /dev/stdin -checkend 1 -noout >/dev/null; then
    # Certificate is not expired
    keys_to_keep=$((keys_to_keep + 1))
  else
    # Certificate is expired
    keys_to_delete+=("$key")
  fi
done

# Publish the sa cert to etcd
$etcdctl put "$etcd_key" < "$SA_CERT_PATH" >/dev/null

if [ "${#keys_to_delete[@]}" -gt 0 ]; then
  # Proceed with deletion only if there are keys to keep
  if [ "$keys_to_keep" -le 0 ]; then
    echo "Error: All certificates are expired, refusing to delete any"
    exit 3
  fi
  for key in "${keys_to_delete[@]}"; do
    $etcdctl del "$key" >/dev/null
  done
fi
