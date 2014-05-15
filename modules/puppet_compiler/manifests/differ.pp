class puppet_compiler::differ(
    $envdir = "${puppet_compiler::program_dir}/shell/env_puppet_3",
    $modulepath = "${puppet_compiler::puppetdir}/modules",
    $user = 'www-data'
    ) {

    exec {"Install catalog diff module_${title}":
        command => "/usr/bin/bundle/ exec puppet module install rpienaar-catalog_diff --modulepath=${modulepath}",
        cwd     => $envdir,
        user    => $user,
        creates => "${modulepath}/catalog_diff",
    }
}
