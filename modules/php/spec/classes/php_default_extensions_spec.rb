require 'spec_helper'
test_on = {
  supported_os: [
    {
      'operatingsystem'        => 'Debian',
      'operatingsystemrelease' => ['9'],
    }
  ]
}

describe 'php::default_extensions' do
  on_supported_os(test_on).each do |_os, facts|
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
