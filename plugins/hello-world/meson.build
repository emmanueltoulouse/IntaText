# Plugin Hello World
glib_dep = dependency('glib-2.0', version: '>= 2.74')
gobject_dep = dependency('gobject-2.0')

plugin_sources = files('HelloWorldPlugin.vala')
plugin_inc = include_directories('.')

# Répertoire d'installation du plugin dans le dossier utilisateur
plugin_user_dir = join_paths(get_option('prefix'), get_option('datadir'), 'intatext', 'plugins', 'hello-world')

shared_module(
    'hello-world',
    plugin_sources,
    dependencies: [glib_dep, gobject_dep],
    vala_args: [
        '--pkg', 'glib-2.0',
        '--pkg', 'gobject-2.0',
    ],
    include_directories: plugin_inc,
    name_prefix: '',
    install: true,
    install_dir: plugin_user_dir,
)

install_data(
    'hello-world.plugin',
    install_dir: plugin_user_dir,
)
