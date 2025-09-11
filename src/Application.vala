/* Application.vala
  *
  * Copyright 2023
  *
  * This program is free software: you can redistribute it and/or modify
  * it under the terms of the GNU General Public License as published by
  * the Free Software Foundation, either version 3 of the License, or
  * (at your option) any later version.
  *
  * This program is distributed in the hope that it will be useful,
  * but WITHOUT ANY WARRANTY; without even the implied warranty of
  * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  * GNU General Public License for more details.
  *
  * You should have received a copy of the GNU General Public License
  * along with this program.  If not, see <http://www.gnu.org/licenses/>.
  */

using Gtk;
using Adw;

namespace IntaText {
public class Application : Adw.Application {
private MainWindow main_window;
private ApplicationModel model;
private ApplicationController controller;
// Stockage direct de l'icône en tant que propriété de classe
private Gdk.Texture? custom_icon = null;

public Application() {
    Object(
        application_id: "com.cabineteto.IntaText",
        flags: ApplicationFlags.HANDLES_OPEN
        );

    // Définir le chemin de base des ressources
    this.set_resource_base_path("/com/cabineteto/IntaText");

    // Vérifier s'il y a une icône personnalisée dans le home directory
    string home_icon = Path.build_filename(Environment.get_home_dir(), "com.cabineteto.IntaText.png");
    if (FileUtils.test(home_icon, FileTest.EXISTS)) {
        try {
            // Stockage direct de la texture comme propriété de classe
            custom_icon = Gdk.Texture.from_file(File.new_for_path(home_icon));
        } catch (Error e) {
            warning("Impossible de charger l'icône personnalisée: %s", e.message);
        }
    }

    // S'assurer que les ressources sont correctement initialisées
    ensure_resources();

    // Charger les styles CSS
    load_css();
}

/**
  * S'assure que les ressources de l'application sont correctement initialisées
  */
private void ensure_resources() {
    // Implémentation réelle ou supprimer la méthode si inutile
    // Par exemple, initialiser des resources GResource
}

private void load_css() {
    try {
        var css_provider = new Gtk.CssProvider();
        css_provider.load_from_string(
            """
                    .rounded {
                        border-radius: 12px;
                    }

                    .tab-button {
                        padding: 6px 12px;
                        margin: 2px;
                        border-radius: 6px;
                    }

                    .tab-button:checked {
                        background-color: alpha(currentColor, 0.15);
                    }

                    /* Styles pour l'explorateur détaché */
                    .explorer-header {
                        font-weight: bold;
                    }

                    /* Autres styles existants... */
                """);

        // Appliquer le CSS
        Gtk.StyleContext.add_provider_for_display(
            Gdk.Display.get_default(),
            css_provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
            );

        // trace supprimée
    } catch (Error e) {
        warning("Erreur lors du chargement du CSS: %s", e.message);
    }
}

protected override void activate() {
    // Initialise le contrôleur d'abord
    controller = new ApplicationController(null, this);

    // Initialise le modèle avec le contrôleur
    model = new ApplicationModel(controller);

    // Mettre à jour le contrôleur avec le modèle
    controller.set_model(model);

    // Charge la configuration depuis le fichier INI
    controller.load_configuration();

    // Bon : le contrôleur lit la config AVANT la création de la fenêtre principale
    controller.init();
    main_window = new MainWindow(this, controller, controller.is_using_detached_explorer());
    controller.set_main_window(main_window);

    // Si nous avons une icône personnalisée, l'appliquer à l'application
    if (custom_icon != null) {
        // Dans GTK4, on définit l'icône au niveau de l'application
        Gtk.IconTheme.get_for_display(Gdk.Display.get_default())
        .add_resource_path("/com/cabineteto/IntaText/icons");
        // L'icône sera utilisée automatiquement par les fenêtres de l'application
    }

    // AJOUT: Appeler initialize pour charger les favoris, etc.
    controller.initialize();

    // Présenter la fenêtre principale
    main_window.present();

    // Appliquer le style éditeur dès le démarrage
    controller.apply_editor_style_from_preferences();

    // Appeler la connexion des signaux APRÈS que toutes les fenêtres
    // (y compris ExplorerWindow potentiellement créée dans init) soient prêtes.
    // Utiliser un court délai pour être sûr que tout est dessiné.
    Timeout.add(100, () => {
                // trace supprimée
                controller.connect_explorer_signals();
                return false; // Exécuter une seule fois
            });
}

protected override void open(File[] files, string hint) {
    // D'abord, activer l'application normalement
    activate();

    // Puis ouvrir le premier fichier spécifié
    if (files.length > 0) {
        string file_path = files[0].get_path();
        if (file_path != null && controller != null) {
            // Utiliser un délai pour s'assurer que l'interface est complètement initialisée
            Timeout.add(200, () => {
                try {
                    controller.handle_file_open_request(file_path);
                } catch (Error e) {
                    warning("Erreur lors de l'ouverture du fichier: %s", e.message);
                }
                return false; // Exécuter une seule fois
            });
        }
    }
}

public override void shutdown() {
    // Nettoyer les plugins avant la fermeture
    if (model != null) {
        model.cleanup();
    }

    base.shutdown();
}

public static int main(string[] args) {
    Adw.init();
    var app = new IntaText.Application();
    return app.run(args);
}
}
}
