class puppet_compiler::packages() {
    $list = [
             'curl',
             'git-core',
             'python-pip',
             'python-dev',
             'ruby1.8',
             'rubygems',
             'ruby-bundler',
             'ruby1.8-dev',
             'mysql-server',
             'mysql-client',
             'ruby-mysql',
             'nginx'
             ]
    package {$list:
        ensure => present
    }
}
