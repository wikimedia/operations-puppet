# SPDX-License-Identifier: Apache-2.0
# == Type: Profile::Mediawiki_deployments
#
# A puppet type that represents a collection of MediaWiki-on-k8s deployments
# managed by Scap, together with how to supervise (i.e., evaluate the health
# of) rollouts to those deployments.
#
# For a detailed description of hash fields, consult the DeploymentsConfig
# docstring in
# https://gitlab.wikimedia.org/repos/releng/scap/-/blob/master/scap/kubernetes.py.
#
type Profile::Mediawiki_deployments = Struct[{
    # deployment_targets describes what deployments exist, what images they
    # should use, and when (i.e., rollout stage) they should be updated.
    'deployment_targets' => Array[Struct[{
        'namespace'   => String,
        'scope'       => Optional[String],
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
        'dir'         => Optional[String],
        'clusters'    => Optional[Array[String]],
    }]],
    # supervision_rules describes how to evaluate the health of deployments
    # updated at a given stage (e.g., logstash checks or smoke-test commands).
    'supervision_rules'  => Array[Struct[{
        'scope'  => String,
        'stages' => Hash[Enum['testservers','canaries','production'], Array[Variant[Struct[{
            'logstash_check' => Struct[{
                'threshold' => Integer,
                'scope'     => Optional[String],
                'stage'     => Optional[Enum['testservers','canaries','production']],
            }],
        }], Struct[{
            'commands' => Array[String],
        }]]]],
    }]],
}]
