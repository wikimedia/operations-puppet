# SPDX-License-Identifier: Apache-2.0
#
# K8s::KubeProxyDetectLocal tells kube-proxy how to identify traffic that comes
# from a Pod on the local node.
#
# kube-proxy uses this to decide if it must masquerade a packet before it sends
# the packet to a Service backend. It does not masquerade local Pod traffic, so
# the backend Pod sees the real client address.
#
# In the default mode, ClusterCIDR, kube-proxy compares the source address with
# clusterCIDR. clusterCIDR holds only one range per IP family. Use
# InterfaceNamePrefix to match the name of the interface that received the
# packet instead. This mode does not use the Pod IP range. Set
# interface_name_prefix to "cali" for a Calico CNI.
#
# The variants make the interface name a required key for the modes that need
# it. kube-proxy refuses to start if the name is absent.
#
# https://kubernetes.io/docs/reference/config-api/kube-proxy-config.v1alpha1/
#
type K8s::KubeProxyDetectLocal = Variant[
    Struct[{
        'mode' => Enum['ClusterCIDR', 'NodeCIDR'],
    }],
    Struct[{
        'mode'                  => Enum['InterfaceNamePrefix'],
        'interface_name_prefix' => String[1],
    }],
    Struct[{
        'mode'             => Enum['BridgeInterface'],
        'bridge_interface' => String[1, 15],
    }],
]
