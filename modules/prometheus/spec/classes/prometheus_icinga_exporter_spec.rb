require_relative '../../../../rake_modules/spec_helper'

describe 'prometheus::icinga_exporter' do
  on_supported_os(WMFConfig.test_on).each do |os, os_facts|
    context "on #{os}" do
      let(:pre_condition) {}
      let(:facts) { os_facts }
      let(:params) { {} }

      describe 'compiles without errors' do
        it { is_expected.to compile.with_all_deps }
      end

      describe 'When export_problems true' do
        let(:params) { super().merge({
          'export_problems' => true,
        }) }

        describe 'When label_teams_config not passed' do
          it { is_expected.to compile.with_all_deps }
          it {
            is_expected.to contain_file('/etc/prometheus/icinga_exporter.label_teams.yml')
              .with_ensure('absent')
          }
        end

        describe 'When label_teams_config passed' do
          let(:params) { super().merge({
            'export_problems' => true,
            'label_teams_config' => {
              'team1' => {'alertname' => ['.*team1.*']},
              'team2' => {'alertname' => ['.*team2.*']},
            },
          }) }

          it { is_expected.to compile.with_all_deps }
          # careful with trailing newlines, as rspec will trim them from the diff
          # when showing the errors
          it {
            is_expected.to contain_file('/etc/prometheus/icinga_exporter.label_teams.yml')
              .with_ensure('present')
              .with_content("---\nteam1:\n  alertname:\n  - \".*team1.*\"\nteam2:\n  alertname:\n  - \".*team2.*\"\n")
          }
        end
      end

      describe 'When export_problems not passed (default false) and labels_teams_config passed' do
        let(:params) { super().merge({
          'export_problems' => false,
          'label_teams_config' => {
             'team1' => {'alertname' => ['.*team1.*']},
             'team2' => {'alertname' => ['.*team2.*']},
          }
        }) }

        it { is_expected.to compile.with_all_deps }
        it {
          is_expected.to contain_file('/etc/prometheus/icinga_exporter.label_teams.yml')
            .with_ensure('absent')
        }
      end
    end
  end
end
