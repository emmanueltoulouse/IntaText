project('IntaText', 'vala', version: '0.1.0',
        license: 'GPL-3.0-or-later',
        default_options: [
            'warning_level=3',
            'debug=true'
        ])

gtk_dep = dependency('gtk4', version: '>=4.1', required: true)
adw_dep = dependency('libadwaita-1', version: '>=1.0', required: true)
gee_dep = dependency('gee-0.8', required: true)
json_dep = dependency('json-glib-1.0', required: true)
gio_dep = dependency('gio-2.0', required: true)

# Import des modules GNOME
gnome = import('gnome')

# Configuration de l'internationalisation
i18n = import('i18n')
gettext_package = meson.project_name().to_lower()

# Définir GETTEXT_PACKAGE pour C et Vala
add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format(gettext_package), language: 'c')
add_global_arguments('--define=GETTEXT_PACKAGE="@0@"'.format(gettext_package), language: 'vala')

# Vérifier si l'icône existe dans le répertoire personnel de l'utilisateur
check_home_icon = run_command('sh', '-c', 'test -f ~/com.cabineteto.IntaText.png && echo yes || echo no', check: false).stdout().strip()

if check_home_icon == 'yes'
  # Copier l'icône depuis le répertoire personnel vers le dossier data
  run_command('mkdir', '-p', 'data/icons/hicolor/scalable/apps', check: false)
  run_command('cp', '~/com.cabineteto.IntaText.png', 'data/icons/hicolor/scalable/apps/', check: false)
endif

# Compilation des ressources GResource
resources = gnome.compile_resources(
  'intatext-resources',
  'data/intatext.gresource.xml',
  source_dir: 'data'
)

sources = [
    # Fichier principal de l'application
    'src/Application.vala',
    'src/HeaderBar.vala',
    'src/PreferencesWindow.vala',
    'src/TextEditor.vala',

    # Modèles
    'src/model/ApplicationModel.vala',
    'src/model/ConfigManager.vala',
    'src/model/EditorModel.vala',

    # Explorateur - Modèles
    'src/model/ExplorerModel.vala',
    'src/model/explorer/BreadcrumbModel.vala',
    'src/model/explorer/ExplorerTabModel.vala',
    'src/model/explorer/FileItemModel.vala',
    'src/model/explorer/ViewMode.vala',
    'src/model/explorer/IconCache.vala',
    'src/model/explorer/SearchService.vala',
    'src/model/explorer/BookmarksManager.vala',
    'src/model/explorer/HistoryManager.vala',

    # Module pivot et convertisseurs (Phase 1)
    'src/model/document/PivotDocument.vala',
    'src/model/document/DocumentConverter.vala',
    'src/model/document/DocumentConverterManager.vala',
    'src/model/document/PivotDocumentConverter.vala',
    'src/model/document/TextDocumentConverter.vala',



    # Module pivot et convertisseurs (Phase 2 enrichie)
    'src/model/document/MarkdownDocumentConverter.vala',
    'src/model/document/HtmlDocumentConverter.vala',

    # Contrôleur
    'src/controller/ApplicationController.vala',

    # Vues principales
    'src/view/MainWindow.vala',
    'src/view/ExplorerView.vala',
    'src/view/EditorView.vala',

    # Fenêtres pour l'explorateur
    'src/view/windows/ExplorerWindow.vala',
    'src/view/windows/PreferencesWindow.vala',

    # Boîtes de dialogue
    'src/view/dialogs/DialogFileComparer.vala',
    'src/view/dialogs/TableEditorDialog.vala',

    # Widgets
    'src/view/widgets/ComparisonView.vala',
    'src/view/widgets/FilePreviewWidget.vala',
    'src/view/widgets/ErrorInfoBar.vala',
    'src/view/widgets/BreadcrumbWidget.vala',
    'src/view/widgets/ExtensionFilterChips.vala',
    'src/view/widgets/WysiwygEditor.vala',

    # Vues supplémentaires à ajouter
    'src/Sidebar.vala',
]

add_project_arguments(['--target-glib=auto'], language: 'vala')

# Assurez-vous que le compilateur valac puisse trouver les packages
add_project_arguments(['--pkg=gtk4', '--pkg=libadwaita-1', '--pkg=gee-0.8', '--pkg=gio-2.0'], language: 'vala')

# Dans votre fichier meson.build principal
add_project_arguments(['--disable-warnings'], language: 'vala')

executable('IntaText',
  sources: sources + resources,
  dependencies: [gtk_dep, adw_dep, gee_dep, json_dep, gio_dep],
  install: true,
  vala_args: ['--Xcc=-lm']
)

# Installation de l'icône
install_data('data/icons/hicolor/scalable/apps/com.cabineteto.IntaText.png',
  install_dir: join_paths(get_option('datadir'), 'icons/hicolor/scalable/apps')
)

# Création et installation du fichier .desktop
conf = configuration_data()
conf.set('ICON', 'com.cabineteto.IntaText')
conf.set('EXEC', 'IntaText')
conf.set('NAME', 'IntaText')

configure_file(
  input: 'data/com.cabineteto.IntaText.desktop.in',
  output: 'com.cabineteto.IntaText.desktop',
  configuration: conf,
  install: true,
  install_dir: join_paths(get_option('datadir'), 'applications')
)

# Configuration pour l'internationalisation
subdir('po')
