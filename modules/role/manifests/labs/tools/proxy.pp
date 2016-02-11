class role::labs::tools::proxy {
    include toollabs::proxy
    include role::toollabs::k8s::webproxy

    system::role { 'role::labs::tools::proxy': description => 'Tool labs generic web proxy' }
}
