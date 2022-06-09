# SPDX-License-Identifier: Apache-2.0
type Envoyproxy::Tlscertificate = Struct[{
    'cert_path' => Stdlib::Unixpath,
    'key_path'  => Stdlib::Unixpath,
    'ocsp_path' => Optional[Stdlib::Unixpath],
}]
