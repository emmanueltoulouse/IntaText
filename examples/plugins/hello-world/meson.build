project('hello-world-plugin', 'vala', 'c',
    version: '1.0.0',
    license: 'GPL-3.0+',
    default_options: [
        'warning_level=2',
    ]
)

# Dépendances
glib_dep = dependency('glib-2.0', version: '>= 2.74')
gobject_dep = dependency('gobject-2.0')
gtk_dep = dependency('gtk4', version: '>= 4.10')
gio_dep = dependency('gio-2.0')

# Inclure les interfaces des plugins depuis le projet principal
plugin_interfaces_dir = '../../../src/model/plugins'

# Sources du plugin
plugin_sources = files(
    'HelloWorldPlugin.vala'
)

# Configuration Vala
vala_args = [
    '--target-glib=2.74',
    '--vapidir=' + plugin_interfaces_dir,
    '--pkg=glib-2.0',
    '--pkg=gobject-2.0',
    '--pkg=gtk4',
    '--pkg=gio-2.0',
    '--library=hello-world-plugin',
    '--gir=HelloWorldPlugin-1.0.gir'
]

# Créer la bibliothèque partagée du plugin
hello_world_plugin = shared_library(
    'hello-world-plugin',
    plugin_sources,
    vala_args: vala_args,
    dependencies: [
        glib_dep,
        gobject_dep,
        gtk_dep,
        gio_dep
    ],
    install: false,  # Ne pas installer automatiquement
    install_dir: get_option('libdir') / 'intatext' / 'plugins'
)

# Copier le fichier .plugin
install_data(
    'hello-world.plugin',
    install_dir: get_option('datadir') / 'intatext' / 'plugins'
)
