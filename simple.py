import os

# Folder + file structure
structure = {
    "lib": {
        "main.dart": "",
        "core": {
            "constants": {
                "app_colors.dart": "",
                "app_strings.dart": "",
                "app_assets.dart": "",
            },
            "utils": {
                "math_utils.dart": "",
                "time_utils.dart": "",
                "logger.dart": "",
            },
            "services": {
                "location_service.dart": "",
                "sensor_service.dart": "",
                "ar_service.dart": "",
                "astronomy_service.dart": "",
                "data_loader.dart": "",
            }
        },
        "data": {
            "models": {
                "star_model.dart": "",
                "constellation_model.dart": "",
                "planet_model.dart": "",
            },
            "repositories": {
                "star_repository.dart": "",
                "constellation_repository.dart": "",
                "planet_repository.dart": "",
            }
        },
        "features": {
            "ar_view": {
                "ar_view_page.dart": "",
                "star_overlay.dart": "",
                "ar_controller.dart": "",
                "ar_widgets.dart": "",
            },
            "star_map": {
                "star_map_page.dart": "",
                "star_map_painter.dart": "",
            },
            "settings": {
                "settings_page.dart": "",
                "settings_controller.dart": "",
            }
        },
        "widgets": {
            "custom_button.dart": "",
            "info_card.dart": "",
            "loading_indicator.dart": "",
        },
        "theme": {
            "light_theme.dart": "",
            "dark_theme.dart": "",
            "app_theme.dart": "",
        }
    }
}


def create_structure(base_path, structure_dict):
    for name, content in structure_dict.items():
        path = os.path.join(base_path, name)

        if isinstance(content, dict):
            # Create folder
            os.makedirs(path, exist_ok=True)
            create_structure(path, content)
        else:
            # Create file
            with open(path, "w") as f:
                f.write(content)


if __name__ == "__main__":
    print("📁 Creating Flutter folder structure...")
    create_structure(".", structure)
    print("✅ Done! Folder structure created successfully.")
