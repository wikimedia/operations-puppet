class role::package-builder {

  system_role { 'role::package-builder': description => 'Debian package builder' }

  include package-builder

  package-builder::pbuilder { 'cowbuilder':
    dists       => 'lucid',
    defaultdist => 'precise',
  }
  package-builder::pbuilder { 'pbuilder':
    dists       => 'lucid',
    defaultdist => 'precise',
  }

}
