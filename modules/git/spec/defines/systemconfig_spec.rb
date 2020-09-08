require 'spec_helper'

describe 'git::systemconfig' do
  context 'Sets a single system config' do
    let(:title) { 'setup_http_proxy' }
    let(:params) { {
      :settings => {
        'http' => {
          'proxy' => 'http://proxy.example.org',
        }
      }
    } }

    it  {
      should contain_file('/etc/gitconfig')
    }
    it {
      should contain_file('/etc/gitconfig.d/setup_http_proxy.gitconfig')
        .with_content(%r{\[http\]\nproxy = http:\/\/proxy\.example\.org$})
    }
  end

  context 'Manages multiple snippets' do
    let(:pre_condition) {
      '''
      git::systemconfig { "first":
        settings => {
          "section1" => {
            "key1" => "value1"
          }
        }
      }
      '''
    }

    let(:title) { 'second' }
    let(:params) { {
      :settings => {
        'section2' => {
          'key2' => 'value2'
        }
      }
    } }
    it 'had a preliminary systemconfig file' do
        should contain_file('/etc/gitconfig.d/first.gitconfig')
    end
    it 'can manage a secondary systemconfig file' do
        should contain_file('/etc/gitconfig.d/second.gitconfig')
    end
  end
end
