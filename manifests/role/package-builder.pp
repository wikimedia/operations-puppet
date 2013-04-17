class role::package-builder {
  system_role { 'role::package-builder': description => 'Debian package builder' }

  pbuilder { 'cowbuilder': }
  pbuilder { 'pbuilder': }

}
