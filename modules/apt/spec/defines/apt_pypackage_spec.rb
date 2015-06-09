require 'spec_helper'
describe 'apt::pypackage', :type => :define do
  describe 'default: only python2 package' do
    let(:title) { 'svn' }
    it { should contain_package('python-svn').with({'ensure' => 'latest'})}
    it { should_not contain_package('python3-svn') }
  end

  describe 'true/false definitions' do
    let(:title) { 'svn' }
    let(:params) { { 'py2' => false, 'py3' => true } }
    it { should_not contain_package('python-svn') }
    it { should contain_package('python3-svn') }
  end

  describe 'overrides global level' do
    let(:title) { 'svn' }
    let(:params) { { 'py3' => 'svnx' } }
    it { should contain_package('python-svn') }
    it { should_not contain_package('python-svnx') }
    it { should contain_package('python3-svnx') }
    it { should_not contain_package('python3-svn') }
  end

  describe 'per-release overrides' do
    let(:title) { 'svn' }
    let(:params) { { 'py3' => { 'trusty' => 'svnx' } } }
    
    context 'on trusty' do
      let(:facts) {{:lsbdistcodename => 'trusty'}}
      it { should contain_package('python-svn') }
      it { should_not contain_package('python-svnx') }
      it { should contain_package('python3-svnx') }
      it { should_not contain_package('python3-svn') }
    end

    context 'on precise' do
      let(:facts) {{:lsbdistcodename => 'precise'}}
      it { should contain_package('python-svn') }
      it { should_not contain_package('python-svnx') }
      it { should_not contain_package('python3-svnx') }
      it { should_not contain_package('python3-svn') }
    end
  end

  describe 'per-release overrides with bool' do
    let(:title) { 'svn' }
    let(:params) { { 'py3' => { 'trusty' => true } } }
    
    context 'on trusty' do
      let(:facts) {{:lsbdistcodename => 'trusty'}}
      it { should contain_package('python-svn') }
      it { should contain_package('python3-svn') }
    end

    context 'on precise' do
      let(:facts) {{:lsbdistcodename => 'precise'}}
      it { should contain_package('python-svn') }
      it { should_not contain_package('python3-svn') }
    end
  end
end
