#!/usr/bin/env python3
"""
Script simple para generar PDFs por carpeta de documentación.
Agrupa archivos por directorio principal y crea un PDF para cada grupo.
"""

import os
import sys
import tempfile
import subprocess
from pathlib import Path
import yaml

PROJECT_ROOT = Path(__file__).parent.parent
VENV_BIN = PROJECT_ROOT / ".venv" / "bin"
DOCS_DIR = PROJECT_ROOT / "docs"
OUTPUT_DIR = PROJECT_ROOT / "site" / "pdfs"

def get_folder_structure():
    """Obtener estructura de carpetas del directorio docs/"""
    folders = {}

    for item in DOCS_DIR.iterdir():
        if item.is_dir() and not item.name.startswith('_'):
            # Recopilar archivos .md en cada carpeta
            md_files = []
            for md_file in item.rglob("*.md"):
                rel_path = md_file.relative_to(DOCS_DIR)
                md_files.append(str(rel_path))

            if md_files:  # Solo incluir carpetas con archivos .md
                folders[item.name] = {
                    'name': item.name.replace('-', ' ').title(),
                    'files': sorted(md_files),
                    'description': f"Documentation for {item.name.replace('-', ' ')}"
                }

    return folders

def create_simple_pdf_config(folder_name, folder_info):
    """Crear configuración MkDocs simple para una carpeta"""

    # Configuración básica
    config = {
        'site_name': f"n8n Docs - {folder_info['name']}",
        'site_description': folder_info['description'],
        'docs_dir': 'docs',
        'theme': {
            'name': 'material',
            'palette': {'scheme': 'light'}
        },
        'nav': [],
        'plugins': [
            'search',
            {
                'with-pdf': {
                    'output_path': f'pdfs/{folder_name}.pdf',
                    'cover_title': folder_info['name'],
                    'cover_subtitle': folder_info['description'],
                    'toc_title': 'Table of Contents'
                }
            }
        ]
    }

    # Crear navegación simple basada en archivos
    for file_path in folder_info['files']:
        # Usar nombre del archivo como título
        file_name = Path(file_path).stem
        title = file_name.replace('-', ' ').title()
        if title.lower() == 'index':
            title = f"{folder_info['name']} Overview"

        config['nav'].append({title: file_path})

    return config

def generate_folder_pdf(folder_name, folder_info):
    """Generar PDF para una carpeta específica"""
    print(f"📄 Generating PDF for: {folder_info['name']} ({len(folder_info['files'])} files)")

    # Crear configuración temporal
    temp_config = create_simple_pdf_config(folder_name, folder_info)

    # Escribir archivo de configuración temporal
    with tempfile.NamedTemporaryFile(mode='w', suffix='.yml', delete=False, encoding='utf-8') as f:
        yaml.dump(temp_config, f, default_flow_style=False, allow_unicode=True)
        temp_config_path = f.name

    try:
        # Ejecutar mkdocs build
        mkdocs_cmd = [
            str(VENV_BIN / "mkdocs"),
            "build",
            "--config-file", temp_config_path,
            "--site-dir", str(PROJECT_ROOT / "site"),
            "--quiet"
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
            pdf_path = OUTPUT_DIR / f"{folder_name}.pdf"
            if pdf_path.exists():
                print(f"✅ PDF created: {pdf_path}")
                return True
            else:
                print(f"❌ PDF not found at {pdf_path}")
                return False
        else:
            print(f"❌ Error generating PDF for {folder_name}:")
            if result.stderr:
                print(result.stderr[:500])  # Limitar salida de error
            return False

    finally:
        # Cleanup
        os.unlink(temp_config_path)

def main():
    """Función principal"""
    if not (VENV_BIN / "mkdocs").exists():
        print("❌ Error: mkdocs not found in .venv/bin/")
        print("Run: pip install mkdocs-with-pdf weasyprint")
        sys.exit(1)

    # Crear directorio de salida
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    print("🚀 Generating PDFs by folder...")

    # Obtener estructura de carpetas
    folders = get_folder_structure()

    if not folders:
        print("❌ No folders with .md files found in docs/")
        sys.exit(1)

    print(f"📁 Found {len(folders)} folders to process:")
    for name, info in folders.items():
        print(f"  - {name}: {len(info['files'])} files")
    print()

    successful = 0
    for folder_name, folder_info in folders.items():
        if generate_folder_pdf(folder_name, folder_info):
            successful += 1
        print()  # Blank line between folders

    print(f"📊 Summary: {successful}/{len(folders)} PDFs generated successfully")
    if successful > 0:
        print(f"📁 PDFs available in: {OUTPUT_DIR}")

if __name__ == "__main__":
    main()
