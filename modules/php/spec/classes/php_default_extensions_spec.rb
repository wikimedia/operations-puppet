require_relative '../../../../rake_modules/spec_helper'

describe 'php::default_extensions' do
  on_supported_os(WMFConfig.test_on(9)).each do |os, facts|
    context "on #{os}" do
      let(:facts) {facts}

      context 'when called alone' do
        it { is_expected.to compile.and_raise_error(/php::default_extensions is a private class/)}
      end

      context 'when called from the php class' do
        let(:pre_condition) { 'include php' }
        it { is_expected.to compile }

        it { is_expected.to contain_php__extension('tokenizer')
          .with_package_name('')
          .with_priority(20)
        }

        it { is_expected.to contain_php__extension('opcache')
          .with_package_name('')
          .with_priority(10)
          .with_config({'zend_extension' => 'opcache.so'})
        }
      end
    end
  end
end
