require_relative '../../../../rake_modules/spec_helper'

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
    it {
        should compile.with_all_deps
    }
    it {
      should contain_file('/etc/gitconfig.d/00-header.gitconfig')
    }
    it {
      should contain_file('/etc/gitconfig.d/10-setup_http_proxy.gitconfig')
        .that_requires('File[/etc/gitconfig.d]')
        .with_content(%r{\[http\]\nproxy = http:\/\/proxy\.example\.org$})
        .that_notifies('Exec[update-gitconfig]')
    }
    it {
        should have_exec_resource_count(1)
    }
  end

  context 'Normalizes .gitconfig filename' do
      let(:title) { 'title with non-words' }
      let(:params) { {
          :settings => {}
      } }
      it {
          should contain_file('/etc/gitconfig.d/10-title_with_non_words.gitconfig')
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
      :priority => 20,
      :settings => {
        'section2' => {
          'key2' => 'value2'
        }
      }
    } }
    it {
        should compile.with_all_deps
    }
    it 'had a preliminary systemconfig file' do
        should contain_file('/etc/gitconfig.d/10-first.gitconfig')
            .that_notifies('Exec[update-gitconfig]')
    end
    it 'can manage a secondary systemconfig file' do
        should contain_file('/etc/gitconfig.d/20-second.gitconfig')
            .that_notifies('Exec[update-gitconfig]')
    end
    it {
        should have_exec_resource_count(1)
    }
  end
end
