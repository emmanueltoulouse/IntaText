# Configuration des tests
test_dependencies = [
    dependency('glib-2.0'),
    dependency('gobject-2.0'),
    dependency('gtk4'),
    dependency('libadwaita-1'),
    dependency('json-glib-1.0'),
    dependency('gee-0.8')
]

# Inclure les sources principales pour les tests
test_include_dirs = include_directories('../src', '../src/model', '../src/model/document')

# Test PivotDocument simple
pivot_document_test = executable(
          'pivot_document_test',
          [
               'unit/pivot_document_test.vala',
               '../src/model/document/PivotDocument.vala',
          ],
          dependencies: test_dependencies,
          include_directories: test_include_dirs,
          install: false
)

test('pivot_document_tests', pivot_document_test,
     suite: 'unit',
     timeout: 30)

# Test DocumentConverterManager
document_converter_test = executable(
    'document_converter_test',
    'unit/document_converter_test.vala',
    dependencies: test_dependencies,
    include_directories: test_include_dirs,
    install: false
)

test('document_converter_tests', document_converter_test,
     suite: 'unit',
     timeout: 60)

# Tests d'indentation - modes
indentation_modes_test = executable(
    'indentation_modes_test',
    'unit/indentation_modes_test.vala',
    dependencies: test_dependencies,
    include_directories: test_include_dirs,
    install: false
)

test('indentation_modes_tests', indentation_modes_test,
     suite: 'unit',
     timeout: 60)

# Tests d'indentation - conversion
indentation_conversion_test = executable(
    'indentation_conversion_test',
    'unit/indentation_conversion_test.vala',
    dependencies: test_dependencies,
    include_directories: test_include_dirs,
    install: false
)

test('indentation_conversion_tests', indentation_conversion_test,
     suite: 'unit',
     timeout: 60)

# Tests d'intégration Python (exécutés via run_tests.sh)
# Ces tests nécessitent l'application compilée
python_integration_tests = find_program('python3', required: false)

if python_integration_tests.found()
    test('file_operations_integration', python_integration_tests,
         args: [files('integration/file_operations_test.py')],
         suite: 'integration',
         timeout: 120)

    test('round_trip_integration', python_integration_tests,
         args: [files('integration/round_trip_test.py')],
         suite: 'integration',
         timeout: 180)

    test('error_handling_integration', python_integration_tests,
         args: [files('integration/error_handling_test.py')],
         suite: 'integration',
         timeout: 240)

    test('indentation_integration', python_integration_tests,
         args: [files('integration/indentation_integration_test.py')],
         suite: 'integration',
         timeout: 120)

    test('indentation_persistence', python_integration_tests,
         args: [files('integration/indentation_persistence_test.py')],
         suite: 'integration',
         timeout: 180)

    test('indentation_ui', python_integration_tests,
         args: [files('ui/indentation_ui_test.py')],
         suite: 'ui',
         timeout: 240)
endif

# Note: Tests plus complexes nécessitent une configuration séparée
# pour éviter les conflits de compilation avec l'application principale
