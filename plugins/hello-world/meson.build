project('hello-world-plugin', 'vala', 'c', version: '1.0.0')

glib_dep = dependency('glib-2.0', version: '>= 2.74')
gobject_dep = dependency('gobject-2.0')

plugin_sources = files('HelloWorldPlugin.vala')
plugin_inc = include_directories('.')

shared_module(
    'hello-world',
    plugin_sources,
    dependencies: [glib_dep, gobject_dep],
    vala_args: [
        '--vapidir', meson.current_source_dir(),
        '--pkg', 'intatext',
        '--pkg', 'glib-2.0',
        '--pkg', 'gobject-2.0',
    ],
    include_directories: plugin_inc,
    name_prefix: '',
    install: false,
)
