class puppet_compiler::differ(
    $envdir     = "${::puppet_compiler::program_dir}/shell/env_puppet_3",
    $modulepath = "${::puppet_compiler::puppetdir}/modules",
    $user       = $::puppet_compiler::user
) {
    exec { 'Install catalog diff module':
        command => "/usr/bin/bundle exec puppet module install zack-catalog_diff --modulepath=${modulepath}",
        cwd     => $envdir,
        user    => $user,
        creates => "${modulepath}/catalog_diff",
    }
}
