# Installs the deployment bundle needed by puppet
define puppet_compiler::bundle(
    $program_dir = $puppet_compiler::program_dir
) {
    $installer = "${program_dir}/shell/installer"
    exec { "install_puppet_bundle_${title}":
        command => "${installer} ${title}",
        user    => $puppet_compiler::user,
        creates => "${program_dir}/shell/env_puppet_${title}/vendor",
        require => Git::Install['operations/software'],
    }
}
