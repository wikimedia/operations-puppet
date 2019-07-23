source 'https://rubygems.org'

gem 'puppet', ENV['PUPPET_GEM_VERSION'] || '~> 4.10.2'
gem 'xmlrpc' if RUBY_VERSION >= '2.4.0'
gem 'puppet-strings', '~> 1.0.0'
gem 'rspec-puppet', '~> 2.6.9'
gem 'rspec-puppet-facts', '~> 1.7', require: false
gem 'puppetlabs_spec_helper', '< 2.0.0'
gem 'safe_yaml', '~> 1.0.5'

gem 'rake', '~> 12.0.0'
gem 'git', '1.3.0'
gem 'puppet-lint', '2.3.6'
gem 'rubocop', '~> 0.49.1', require: false
gem 'puppet-lint-wmf_styleguide-check', '1.0.4'

# Theses are required for running beaker acceptance test
# you can forgo installing them using `bundle install --without system_tests`
group :system_tests do
  gem 'serverspec',                         :require => false
  gem 'beaker-rspec',                       :require => false
  gem 'beaker-hostgenerator', '>= 1.1.22',  :require => false
  gem 'beaker-docker',                      :require => false
  gem 'beaker-puppet',                      :require => false
  gem 'beaker-puppet_install_helper',       :require => false
  gem 'beaker-module_install_helper',       :require => false
  gem 'rbnacl', '< 5',                      :require => false
  # better to install libsodium natively
  # gem 'rbnacl-libsodium',                   :require => false
  gem 'bcrypt_pbkdf',                       :require => false
  gem 'ed25519'
end
