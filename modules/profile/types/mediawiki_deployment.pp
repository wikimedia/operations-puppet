# SPDX-License-Identifier: Apache-2.0
# == Type: Profile::Mediawiki_deployment
#
# A puppet hash that represents a single Scap DeploymentsConfig file item,
# corresponding to a single MediaWiki-on-k8s deployment managed by Scap.
#
# For a detailed description of hash fields, consult the DeploymentsConfig
# docstring in
# https://gitlab.wikimedia.org/repos/releng/scap/-/blob/master/scap/kubernetes.py.
#
type Profile::Mediawiki_deployment = Struct[{
    'namespace'   => String,
    'releases'    => Hash[String, Struct[{
        'mw_kind'     => Optional[String],
        'mw_flavour'  => Optional[String],
        'web_flavour' => Optional[String],
        'stage'       => Optional[Enum['testservers','canaries','production']],
        'deploy'      => Optional[Boolean],
    }]],
    'mw_kind'     => Optional[String],
    'mw_flavour'  => String,
    'web_flavour' => String,
    # TODO: T389499 - Remove support for debug.
    'debug'       => Optional[Boolean],
}]
