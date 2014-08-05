class puppet_compiler::packages($ensure = $puppet_compiler::ensure) {
    $list = [
             'curl',
             'python-pip',
             'python-dev',
             'rubygems',
             'ruby-bundler',
             'ruby1.8-dev',
             'mysql-server',
             'mysql-client',
             'ruby-mysql',
             'ruby-bcrypt',
             'nginx'
             ]
    ensure_packages([$list])
}
