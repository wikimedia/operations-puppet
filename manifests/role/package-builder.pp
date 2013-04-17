class role::package-builder {

  system_role { 'role::package-builder': description => 'Debian package builder' }

  pbuilder::pbuilder { 'cowbuilder':
    dists       => 'lucid',
    defaultdist => 'precise',
  }
  pbuilder::pbuilder { 'pbuilder':
    dists       => 'lucid',
    defaultdist => 'precise',
  }

}
