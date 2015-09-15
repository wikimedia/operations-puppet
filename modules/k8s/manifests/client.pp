class k8s::client {

    include k8s::ssl

    require_package('kubectl')
}
