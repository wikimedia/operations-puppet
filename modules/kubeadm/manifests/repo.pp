class kubeadm::repo (
    String $component = 'thirdparty/kubeadm-k8s-1-18',
) {
    $repo_name = 'kubeadm-k8s-component-repo'
    apt::repository { $repo_name:
        uri        => 'http://apt.wikimedia.org/wikimedia',
        dist       => 'buster-wikimedia',
        components => $component,
        notify     => Exec['apt-get update'],
    }

    # this exec is defined in apt::repository
    Exec['apt-get update'] -> Package <| tag == 'kubeadm-k8s' |>
}
