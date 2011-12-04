# mono.pp

# Virtual resource for the mono libraries


class mono {
        class packages {
                package { [ 'libjpeg62', 'libtiff4', 'libexif12', 'libgif4', 'libgdiplus', 'libmono-data-tds2.0-cil', 'libmono-messaging2.0-cil', 'libmono-sharpzip2.84-cil', 'libmono-system-data2.0-cil', 'libsqlite0', 'libmono-sqlite2.0-cil', 'libmono-system-messaging2.0-cil', 'libmono2.0-cil', 'libmono-system-web2.0-cil', 'libmono-wcf3.0-cilysql-client-5.1', libmono-system-data-linq2.0-cil', 'libmono-system-web-mvc2.0-cil', 'mono-2.0-gac', 'mono-gac', 'mono-runtime', 'libmono-i18n-west2.0-cil', 'libmono-security2.0-cil', 'libmono-posix2.0-cil', 'libmono-management2.0-cil', 'mono-gmcs', 'mono-csharp-shell' ]:
			ensure => latest;
                }
        }
}
