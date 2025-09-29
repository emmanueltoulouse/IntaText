# Configuration des Tests de Non-Régression - IntaText
# =======================================================

# Configuration générale
TIMEOUT_DEFAULT = 30
VERBOSE_DEFAULT = False
PARALLEL_DEFAULT = False

# Répertoires
TEMP_DIR_PREFIX = "intatext_regression_"
BASELINE_DIR = "baselines"
REPORTS_DIR = "reports"

# Catégories de tests et leurs priorités
TEST_CATEGORIES = {
    "formatage_base": {
        "priority": 1,
        "description": "Tests de formatage de base (gras, italique, code, etc.)",
        "critical": True
    },
    "formatage_combiné": {
        "priority": 1,
        "description": "Tests de formatages combinés",
        "critical": True
    },
    "titres": {
        "priority": 1,
        "description": "Tests des titres H1-H6",
        "critical": True
    },
    "titres_formatage": {
        "priority": 2,
        "description": "Tests des titres avec formatage",
        "critical": False
    },
    "listes": {
        "priority": 1,
        "description": "Tests des listes à puces et numérotées",
        "critical": True
    },
    "listes_formatage": {
        "priority": 2,
        "description": "Tests des listes avec formatage",
        "critical": False
    },
    "citations": {
        "priority": 2,
        "description": "Tests des citations",
        "critical": False
    },
    "citations_formatage": {
        "priority": 3,
        "description": "Tests des citations avec formatage",
        "critical": False
    },
    "code": {
        "priority": 1,
        "description": "Tests des blocs de code",
        "critical": True
    },
    "tableaux": {
        "priority": 2,
        "description": "Tests des tableaux",
        "critical": False
    },
    "tableaux_formatage": {
        "priority": 3,
        "description": "Tests des tableaux avec formatage",
        "critical": False
    },
    "liens": {
        "priority": 2,
        "description": "Tests des liens",
        "critical": False
    },
    "liens_formatage": {
        "priority": 3,
        "description": "Tests des liens avec formatage",
        "critical": False
    },
    "images": {
        "priority": 2,
        "description": "Tests des images",
        "critical": False
    },
    "formatage_avancé": {
        "priority": 3,
        "description": "Tests du formatage avancé (couleurs, polices)",
        "critical": False
    },
    "imbrication": {
        "priority": 2,
        "description": "Tests d'imbrication de fonctionnalités",
        "critical": True
    },
    "cas_limites": {
        "priority": 2,
        "description": "Tests de cas limites et edge cases",
        "critical": True
    },
    "plugins": {
        "priority": 3,
        "description": "Tests des fonctionnalités plugins",
        "critical": False
    },
    "document": {
        "priority": 1,
        "description": "Tests des opérations sur documents",
        "critical": True
    },
    "ui_wysiwyg": {
        "priority": 1,
        "description": "Tests de l'interface WYSIWYG via accessibilité",
        "critical": True
    },
    "ui_wysiwyg_imbrication": {
        "priority": 2,
        "description": "Tests d'imbrication dans l'interface WYSIWYG",
        "critical": True
    },
    "ui_wysiwyg_integration": {
        "priority": 3,
        "description": "Tests d'intégration complexe de l'interface WYSIWYG",
        "critical": False
    },
    "ui_wysiwyg_interaction": {
        "priority": 2,
        "description": "Tests d'interaction utilisateur dans WYSIWYG",
        "critical": False
    }
}

# Tags disponibles pour l'organisation
AVAILABLE_TAGS = [
    "formatage", "gras", "italique", "souligné", "barré", "code",
    "titre", "h1", "h2", "h3", "h4", "h5", "h6",
    "liste", "puces", "numérotée", "tâches", "checkbox",
    "citation", "tableaux", "alignement",
    "lien", "référence", "image",
    "couleur", "police", "span", "styles",
    "imbrication", "combiné", "complexe",
    "cas_limite", "unicode", "emojis", "échappement",
    "plugin", "ui", "format", "export",
    "document", "sauvegarde", "chargement", "roundtrip", "conversion",
    "wysiwyg", "accessibilité", "interface", "interaction", "clavier", "raccourcis",
    "bascule", "intégration"
]

# Seuils de qualité
QUALITY_THRESHOLDS = {
    "excellent": 98,    # > 98% de réussite
    "good": 95,         # > 95% de réussite
    "acceptable": 85,   # > 85% de réussite
    "poor": 70,         # > 70% de réussite
    "critical": 0       # <= 70% de réussite
}

# Configuration des rapports
REPORT_CONFIG = {
    "include_diff": True,
    "max_diff_lines": 50,
    "include_timing": True,
    "include_categories": True,
    "include_priorities": True,
    "json_format": True,
    "html_format": False
}

# Configuration des baselines
BASELINE_CONFIG = {
    "auto_create": False,
    "auto_update": False,
    "version_control": True,
    "backup_on_update": True
}

# Configuration des tests UI
UI_TEST_CONFIG = {
    "enable_ui_tests": True,
    "ui_timeout": 60,
    "ui_retry_count": 3,
    "ui_wait_time": 0.5,
    "accessibility_required": True,
    "screenshot_on_failure": True,
    "ui_test_display": ":0"
}

# Outils externes
EXTERNAL_TOOLS = {
    "markdown_rt": "md_rt",
    "wysiwyg_rt": "md_wysiwyg_rt",
    "intatext_app": "IntaText"
}

# Expressions régulières pour la validation
VALIDATION_PATTERNS = {
    "bold_asterisk": r'\*\*([^*]+)\*\*',
    "bold_underscore": r'__([^_]+)__',
    "italic_asterisk": r'\*([^*]+)\*',
    "italic_underscore": r'_([^_]+)_',
    "code_inline": r'`([^`]+)`',
    "code_fence": r'```(\w*)\n(.*?)\n```',
    "heading_atx": r'^(#{1,6})\s+(.+)$',
    "heading_setext_1": r'^(.+)\n=+$',
    "heading_setext_2": r'^(.+)\n-+$',
    "list_bullet": r'^[\s]*[-*+]\s+(.+)$',
    "list_numbered": r'^[\s]*\d+\.\s+(.+)$',
    "list_task": r'^[\s]*-\s+\[[x\s]\]\s+(.+)$',
    "quote": r'^>\s*(.+)$',
    "table_row": r'^\|(.+)\|$',
    "link": r'\[([^\]]+)\]\(([^)]+)\)',
    "image": r'!\[([^\]]*)\]\(([^)]+)\)',
    "html_tag": r'<(\w+)([^>]*)>(.*?)</\1>',
    "strikethrough": r'~~([^~]+)~~'
}

# Configuration de simulation (fallback)
SIMULATION_CONFIG = {
    "enabled": True,
    "basic_validation": True,
    "pattern_matching": True,
    "complexity_scoring": True
}

# Métriques de qualité
QUALITY_METRICS = [
    "test_coverage",        # Couverture des fonctionnalités
    "success_rate",         # Taux de réussite global
    "critical_success",     # Réussite des tests critiques
    "performance",          # Performance d'exécution
    "stability",            # Stabilité entre les exécutions
    "regression_detection"  # Détection des régressions
]

# Messages d'erreur standardisés
ERROR_MESSAGES = {
    "timeout": "Timeout d'exécution dépassé",
    "dependency_failed": "Dépendance échouée",
    "tool_not_found": "Outil non trouvé",
    "file_not_found": "Fichier non trouvé",
    "parsing_error": "Erreur d'analyse",
    "validation_failed": "Validation échouée",
    "baseline_mismatch": "Différence avec la baseline",
    "conversion_error": "Erreur de conversion",
    "plugin_error": "Erreur de plugin",
    "application_error": "Erreur d'application"
}
