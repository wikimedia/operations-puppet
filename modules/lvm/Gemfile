source "https://rubygems.org"

group :development, :test do
  gem 'rake'
  gem 'rspec', "~> 3.1.0", :require => false
  gem 'mocha', "~> 0.10.5", :require => false
  gem 'puppetlabs_spec_helper', :require => false
end

if puppetversion = ENV['PUPPET_GEM_VERSION']
  gem 'puppet', puppetversion, :require => false
else
  gem 'puppet', :require => false
end

gem 'puppet-lint', '>= 1.0.0'
gem 'puppet-lint-unquoted_string-check', :require => false

if RUBY_VERSION < '2.0'
      gem 'mime-types', '<3.0', :require => false
end

group :system_tests do
  if beaker_version = ENV['BEAKER_VERSION']
    gem 'beaker', *location_for(beaker_version)
  end
  gem 'beaker-puppet_install_helper', :require => false
  gem 'master_manipulator', '~> 1.2',  :require => false
end
# vim:ft=ruby
