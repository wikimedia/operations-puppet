require_relative '../../../../rake_modules/spec_helper'
paths = {
  'default' => {
      "cert" => "/etc/cfssl/ssl/foo__foo_example_com/foo__foo_example_com.pem",
      "key"  => "/etc/cfssl/ssl/foo__foo_example_com/foo__foo_example_com-key.pem"
  },
  'fqdn' => {
      "cert" => "/etc/cfssl/ssl/foo__foobar/foo__foobar.pem",
      "key"  => "/etc/cfssl/ssl/foo__foobar/foo__foobar-key.pem"
  },
  'outdir' => {
      "cert" => "/foobar/foo__foobar.pem",
      "key"  => "/foobar/foo__foobar-key.pem"
  },
  'provide_chain' => {
      "cert" => "/etc/cfssl/ssl/foo__foobar/foo__foobar.pem",
      "key"  => "/etc/cfssl/ssl/foo__foobar/foo__foobar-key.pem",
      "ca" => "/etc/cfssl/ssl/foo__foobar/foo_chain.pem"
  },
  'outdir+provide_chain' => {
      "cert" => "/foobar/foo__foobar.pem",
      "key"  => "/foobar/foo__foobar-key.pem",
      "ca" => "/foobar/foo_chain.pem"
  }
}

describe 'profile::pki::get_cert' do
  on_supported_os(WMFConfig.test_on).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      let(:pre_condition) { 'class{"profile::pki::client": ensure => "present"}' }

      it { is_expected.to run.with_params('foo').and_return(paths['default']) }
      it { is_expected.to run.with_params('foo', 'foobar').and_return(paths['fqdn']) }
      it do
        is_expected.to run.with_params('foo', 'foobar', {'outdir' => '/foobar'})
          .and_return(paths['outdir'])
      end
      it do
        is_expected.to run.with_params('foo', 'foobar', {'provide_chain' => true})
          .and_return(paths['provide_chain'])
      end
      it do
        is_expected.to run.with_params('foo', 'foobar', {'outdir' => '/foobar', 'provide_chain' => true})
          .and_return(paths['outdir+provide_chain'])
      end
    end
  end
end
