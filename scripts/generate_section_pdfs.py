#!/usr/bin/env python3
"""
Script para generar PDFs por sección de la documentación de n8n.
Crea configuraciones temporales de MkDocs para cada sección principal.
"""

import os
import sys
import tempfile
import subprocess
from pathlib import Path
import yaml

# Configuración base del directorio del proyecto
PROJECT_ROOT = Path(__file__).parent.parent
VENV_BIN = PROJECT_ROOT / ".venv" / "bin"
MKDOCS_LOCAL = PROJECT_ROOT / "mkdocs.local.yml"
OUTPUT_DIR = PROJECT_ROOT / "site" / "pdfs"

# Definir las secciones principales que queremos como PDFs separados
SECTIONS = {
    "getting-started": {
        "name": "Getting Started with n8n",
        "nav_patterns": [
            "index.md",
            "learning-path.md",
            "choose-n8n.md",
            "try-it-out/*",
            "video-courses.md",
            "courses/*"
        ],
        "description": "Getting started guide and tutorials"
    },
    "workflows": {
        "name": "Workflows and Components",
        "nav_patterns": [
            "workflows/*"
        ],
        "description": "Understanding and working with workflows"
    },
    "credentials": {
        "name": "Credentials Management",
        "nav_patterns": [
            "credentials/*"
        ],
        "description": "Managing and sharing credentials"
    },
    "user-management": {
        "name": "User Management and Access",
        "nav_patterns": [
            "user-management/*"
        ],
        "description": "Users, roles, and access control"
    },
    "flow-logic": {
        "name": "Flow Logic and Control",
        "nav_patterns": [
            "flow-logic/*"
        ],
        "description": "Conditional logic, loops, and error handling"
    },
    "data": {
        "name": "Data Processing",
        "nav_patterns": [
            "data/*"
        ],
        "description": "Data structure, transformation, and mapping"
    },
    "cloud": {
        "name": "n8n Cloud",
        "nav_patterns": [
            "manage-cloud/*"
        ],
        "description": "n8n Cloud features and management"
    },
    "enterprise": {
        "name": "Enterprise Features",
        "nav_patterns": [
            "source-control-environments/*",
            "external-secrets.md",
            "log-streaming.md"
        ],
        "description": "Enterprise features: source control, secrets, logging"
    },
    "hosting": {
        "name": "Self-Hosting",
        "nav_patterns": [
            "hosting/*"
        ],
        "description": "Self-hosting n8n setup and configuration"
    },
    "integrations": {
        "name": "Integrations and Nodes",
        "nav_patterns": [
            "integrations/*"
        ],
        "description": "Available integrations and node documentation"
    }
}

def load_base_config():
    """Cargar la configuración base de mkdocs.local.yml"""
    with open(MKDOCS_LOCAL, 'r', encoding='utf-8') as f:
        return yaml.safe_load(f)

def create_section_nav(section_config, full_nav):
    """Crear navegación filtrada para una sección específica"""
    patterns = section_config["nav_patterns"]

    def matches_pattern(path, patterns):
        """Verificar si un path coincide con algún patrón"""
        if isinstance(path, dict):
            return False
        for pattern in patterns:
            if pattern.endswith('/*') and path.startswith(pattern[:-2]):
                return True
            elif pattern.endswith('*') and path.startswith(pattern[:-1]):
                return True
            elif path == pattern:
                return True
        return False

    def extract_matching_items(nav_items):
        """Extraer elementos que coincidan con los patrones recursivamente"""
        result = []
        for item in nav_items:
            if isinstance(item, dict):
                for key, value in item.items():
                    if isinstance(value, str) and matches_pattern(value, patterns):
                        result.append({key: value})
                    elif isinstance(value, list):
                        sub_items = extract_matching_items(value)
                        if sub_items:
                            result.append({key: sub_items})
            elif isinstance(item, str) and matches_pattern(item, patterns):
                result.append(item)
        return result

    return extract_matching_items(full_nav.get('nav', []))

def create_temp_config(section_key, section_config, base_config):
    """Crear configuración temporal para una sección"""
    # Cargar navegación completa del nav.yml
    nav_file = PROJECT_ROOT / "nav.yml"
    with open(nav_file, 'r', encoding='utf-8') as f:
        nav_data = yaml.safe_load(f)

    # Crear configuración para esta sección
    temp_config = base_config.copy()

    # Actualizar metadatos
    temp_config['site_name'] = f"n8n Docs - {section_config['name']}"
    temp_config['site_description'] = section_config['description']

    # Filtrar navegación
    section_nav = create_section_nav(section_config, nav_data)
    if section_nav:
        temp_config['nav'] = section_nav
    else:
        print(f"⚠️  Warning: No pages found for section '{section_key}'")
        return None

    # Configurar plugin PDF
    plugins = temp_config.get('plugins', [])
    pdf_plugin_config = {
        'output_path': f'pdfs/{section_key}.pdf',
        'enabled_if_env': 'ENABLE_PDF_EXPORT',
        'cover_title': section_config['name'],
        'cover_subtitle': section_config['description'],
        'cover_logo': '_images/n8n-docs-icon.svg',
        'toc_title': 'Table of Contents'
    }

    # Actualizar o añadir plugin with-pdf
    pdf_plugin_found = False
    for i, plugin in enumerate(plugins):
        if isinstance(plugin, dict) and 'with-pdf' in plugin:
            plugins[i] = {'with-pdf': pdf_plugin_config}
            pdf_plugin_found = True
            break

    if not pdf_plugin_found:
        plugins.append({'with-pdf': pdf_plugin_config})

    temp_config['plugins'] = plugins

    return temp_config

def generate_section_pdf(section_key, section_config):
    """Generar PDF para una sección específica"""
    print(f"📄 Generando PDF para: {section_config['name']}")

    # Cargar configuración base
    base_config = load_base_config()

    # Crear configuración temporal
    temp_config = create_temp_config(section_key, section_config, base_config)
    if not temp_config:
        return False

    # Crear archivo temporal de configuración
    with tempfile.NamedTemporaryFile(mode='w', suffix='.yml', delete=False, encoding='utf-8') as f:
        yaml.dump(temp_config, f, default_flow_style=False, allow_unicode=True)
        temp_config_path = f.name

    try:
        # Ejecutar mkdocs build
        mkdocs_cmd = [
            str(VENV_BIN / "mkdocs"),
            "build",
            "--config-file", temp_config_path,
            "--site-dir", str(PROJECT_ROOT / "site")
        ]

        env = os.environ.copy()
        env['ENABLE_PDF_EXPORT'] = '1'

        result = subprocess.run(
            mkdocs_cmd,
            cwd=PROJECT_ROOT,
            env=env,
            capture_output=True,
            text=True,
            check=False
        )

        if result.returncode == 0:
            pdf_path = PROJECT_ROOT / "site" / "pdfs" / f"{section_key}.pdf"
            if pdf_path.exists():
                print(f"✅ PDF generado: {pdf_path}")
                return True
            else:
                print(f"❌ Error: PDF no encontrado en {pdf_path}")
                return False
        else:
            print(f"❌ Error generando PDF para {section_key}:")
            print(result.stderr)
            return False

    finally:
        # Limpiar archivo temporal
        os.unlink(temp_config_path)

def main():
    """Función principal"""
    if not (VENV_BIN / "mkdocs").exists():
        print("❌ Error: mkdocs no encontrado en .venv/bin/")
        print("Ejecuta: pip install mkdocs-with-pdf")
        sys.exit(1)

    # Crear directorio de salida
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    print("🚀 Generando PDFs por sección...")

    successful = 0
    total = len(SECTIONS)

    for section_key, section_config in SECTIONS.items():
        if generate_section_pdf(section_key, section_config):
            successful += 1
        print()  # Línea en blanco entre secciones

    print(f"📊 Resumen: {successful}/{total} PDFs generados correctamente")

    if successful > 0:
        print(f"📁 PDFs disponibles en: {OUTPUT_DIR}")

if __name__ == "__main__":
    main()
