class SpecDependencies
  # Finds all specs to run based on the changed modules.

  def initialize
    @deps = {}
    # Scan all the modules that have spec tests and dependencies
    # from other modules (thus have a .fixtures.yaml file),
    # read the contents of the fixtures file and create a
    # one-level dependency tree. It could be debatable if we should
    # include higher order, indirect dependencies (if module C depends on module
    # B that depends on module A, should we add it to the dependencies of C?),
    # but we chose not to go that way as each module should just care about the
    # interfaces it uses directly.
    FileList["modules/*/.fixtures.yml"].each do |file|
      module_name = module_from_filename(file)
      symlinks = YAML.safe_load(File.open(file))['fixtures']['symlinks'].keys.select{ |x| x != module_name }
      symlinks.each do |dependency|
        @deps[dependency] ||= []
        @deps[dependency] << module_name
      end
    end
  end

  def specs_to_run(filelist)
    # Extract a list of specs to run. For each module touched by the current
    # change, we add all its dependencies and the module itself only if it has a
    # spec to run
    specs = Set.new
    modules = modules_modified(filelist)
    return [] unless modules
    modules.each do |mod|
      specs.add(mod) if Dir.exists?("modules/#{mod}/spec")
      if @deps.include?mod
        @deps[mod].each{ |m| specs.add(m) }
      end
    end
    specs.to_a
  end

  def tox_to_run(filelist)
    # Scan all the modules with a changed python file for tox.ini,
    # and return them as a list of modules
    mods_to_test = Set.new
    modules = modules_modified(filelist)
    return [] unless modules
    modules.each do |mod|
      mods_to_test.add(mod) if File.exists? "modules/#{mod}/tox.ini"
    end
    mods_to_test
  end

  private

  def modules_modified(filelist)
    modules = Set.new
    filelist.each do |file|
      module_name = module_from_filename(file)

      modules.add(module_name) if module_name
    end
    modules.to_a
  end

  def module_from_filename(name)
    if %r{modules/([^/]+)} =~ name
      Regexp.last_match(1)
    else
      nil
    end
  end
end
