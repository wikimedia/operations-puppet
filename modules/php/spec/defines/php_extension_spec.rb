require 'spec_helper'
test_on = {
  supported_os: [
    {
      'operatingsystem'        => 'Debian',
      'operatingsystemrelease' => ['9'],
    }
  ]
}

describe 'php::extension' do
  on_supported_os(test_on).each do |_os, facts|
    let(:facts) {facts}
    let(:title) { 'xml' }
    context 'when php is defined' do
      let(:pre_condition) { 'include php' }

      context 'with default parameters' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_file('/etc/php/7.0/mods-available/xml.ini')
                              .with_content(/extension = xml.so/)
                              .with_ensure('present')
                              .with_tag(['php::config::cli'])
        }
        it { is_expected.to contain_file('/etc/php/7.0/cli/conf.d/20-xml.ini')
                              .with_ensure('link')
                              .with_target('/etc/php/7.0/mods-available/xml.ini')
        }
        it { is_expected.to contain_package('php-xml')
                              .with_ensure('present')
                              .that_requires('File[/etc/php/7.0/mods-available/xml.ini]')
        }
      end
      context 'with ensure absent' do
        let(:params) {
          {'ensure' => 'absent'}
        }
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_file('/etc/php/7.0/mods-available/xml.ini')
                              .with_ensure('absent')
                              .with_tag(['php::config::cli'])
        }
        it { is_expected.to contain_file('/etc/php/7.0/cli/conf.d/20-xml.ini')
                              .with_ensure('absent')
        }
        it { is_expected.to contain_package('php-xml')
                              .with_ensure('absent')
                              .that_requires('File[/etc/php/7.0/mods-available/xml.ini]')
        }
      end
      context 'with empty package name' do
        let(:params) {
          {'package_name' => ''}
        }
        it { is_expected.to compile.with_all_deps }
        it 'should not contain packages' do
          is_expected.not_to contain_package('php-xml')
        end
      end
      context 'with different priority' do
        let(:params){
          {'priority' => 15}
        }
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_file('/etc/php/7.0/mods-available/xml.ini')
                              .with_content(/; priority=15/)
                              .with_ensure('present')
                              .with_tag(['php::config::cli'])
        }
        it { is_expected.to contain_file('/etc/php/7.0/cli/conf.d/15-xml.ini')
                              .with_ensure('link')
        }
      end
      context 'with custom config' do
        let(:params) {
          {'config' => {'foo' => {'bar' => 'FooBar'}}}
        }
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_file('/etc/php/7.0/mods-available/xml.ini')
                              .with_content(/foo.bar = FooBar/)
                              .with_ensure('present')
                              .with_tag(['php::config::cli'])
        }
      end
      context 'with a non-default sapi' do
        let(:params) {
          {'sapis' => ['fpm']}
        }
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_file('/etc/php/7.0/mods-available/xml.ini')
                              .with_content(/extension = xml.so/)
                              .with_ensure('present')
                              .with_tag(['php::config::fpm'])
        }
        it { is_expected.to contain_file('/etc/php/7.0/fpm/conf.d/20-xml.ini')
                              .with_ensure('link')
                              .with_target('/etc/php/7.0/mods-available/xml.ini')
        }
        it { is_expected.to contain_package('php-xml')
                              .with_ensure('present')
                              .that_requires('File[/etc/php/7.0/mods-available/xml.ini]')
                              .with_tag(['php::package::fpm'])
        }
      end
    end
    context 'when php is not declared' do
      it { is_expected.to compile.and_raise_error(/php::extension is not meant to /)}
    end
  end
end
