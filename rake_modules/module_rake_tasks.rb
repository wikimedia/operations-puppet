require 'puppetlabs_spec_helper/rake_tasks'
private_repo = 'https://gerrit.wikimedia.org/r/labs/private'
fixture_path = File.join(__dir__, '..', 'spec', 'fixtures')
private_modules_path = File.join(fixture_path, 'private')
# This stops the fixtures dir being configured which is
# something we do manually in rake_modules/spec_helper.rb
Rake::Task[:spec_prep].clear
unless ENV['SPEC_PREP_DONE'] == 'DONE'
  task :spec_prep do
    if File.exist?(File.join(private_modules_path, '.git'))
      system('git', '-C', private_modules_path, 'pull', out: File::NULL)
    else
      system('git', 'clone', private_repo, private_modules_path, out: File::NULL)
    end
  end
end
