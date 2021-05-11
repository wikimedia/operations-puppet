require_relative '../../../../rake_modules/spec_helper'
paths = {
  'default' => {
      "cert" => "/etc/cfssl/ssl/foo__foo_example_com/foo__foo_example_com.pem",
      "key"  => "/etc/cfssl/ssl/foo__foo_example_com/foo__foo_example_com-key.pem",
      "chain" => "/etc/cfssl/ssl/foo__foo_example_com/foo__foo_example_com.chain.pem",
      "chained" => "/etc/cfssl/ssl/foo__foo_example_com/foo__foo_example_com.chained.pem"
  },
  'fqdn.unsafe.label' => {
      "cert" => "/etc/cfssl/ssl/fqdn_unsafe_label__foo_example_com/fqdn_unsafe_label__foo_example_com.pem",
      "key"  => "/etc/cfssl/ssl/fqdn_unsafe_label__foo_example_com/fqdn_unsafe_label__foo_example_com-key.pem",
      "chain" => "/etc/cfssl/ssl/fqdn_unsafe_label__foo_example_com/fqdn_unsafe_label__foo_example_com.chain.pem",
      "chained" => "/etc/cfssl/ssl/fqdn_unsafe_label__foo_example_com/fqdn_unsafe_label__foo_example_com.chained.pem"
  },
  'fqdn' => {
      "cert"    => "/etc/cfssl/ssl/foo__foobar/foo__foobar.pem",
      "key"     => "/etc/cfssl/ssl/foo__foobar/foo__foobar-key.pem",
      "chain"   => "/etc/cfssl/ssl/foo__foobar/foo__foobar.chain.pem",
      "chained" => "/etc/cfssl/ssl/foo__foobar/foo__foobar.chained.pem"
  },
  'outdir' => {
      "cert" => "/foobar/foo__foobar.pem",
      "key"  => "/foobar/foo__foobar-key.pem",
      "chain" => "/foobar/foo__foobar.chain.pem",
      "chained" => "/foobar/foo__foobar.chained.pem"
  },
  'outdir+provide_chain' => {
      "cert" => "/foobar/foo__foobar.pem",
      "key"  => "/foobar/foo__foobar-key.pem",
      "chain" => "/foobar/foo__foobar.chain.pem",
      "chained" => "/foobar/foo__foobar.chained.pem"
  }
}

describe 'profile::pki::get_cert' do
  on_supported_os(WMFConfig.test_on).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      let(:pre_condition) { 'class{"profile::pki::client": ensure => "present"}' }

      it { is_expected.to run.with_params('foo').and_return(paths['default']) }
      it { is_expected.to run.with_params('fqdn.unsafe.label').and_return(paths['fqdn.unsafe.label']) }
      it { is_expected.to run.with_params('foo', 'foobar').and_return(paths['fqdn']) }
      it do
        is_expected.to run.with_params('foo', 'foobar', {'outdir' => '/foobar'})
          .and_return(paths['outdir'])
      end
      it do
        is_expected.to run.with_params('foo', 'foobar', {'outdir' => '/foobar', 'provide_chain' => true})
          .and_return(paths['outdir+provide_chain'])
      end
    end
  end
end
