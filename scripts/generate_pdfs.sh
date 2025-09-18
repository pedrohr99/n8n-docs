#!/usr/bin/env bash
set -euo pipefail

# Script principal para generar PDFs de la documentación de n8n
# Permite elegir entre generar un PDF completo, PDFs por sección, o PDFs por carpeta

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
VENV="$ROOT_DIR/.venv"
SCRIPTS_DIR="$ROOT_DIR/scripts"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

echo_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

echo_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

echo_error() {
    echo -e "${RED}❌ $1${NC}"
}

check_dependencies() {
    echo_info "Checking dependencies..."

    if [ ! -d "$VENV" ]; then
        echo_error "Virtual environment not found at $VENV"
        echo "Create it with: python -m venv .venv"
        exit 1
    fi

    if [ ! -f "$VENV/bin/mkdocs" ]; then
        echo_error "MkDocs not found in virtual environment"
        echo "Install with: $VENV/bin/pip install -r requirements.txt"
        exit 1
    fi

    # Check for WeasyPrint dependencies on macOS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if ! brew list cairo &>/dev/null; then
            echo_warning "WeasyPrint dependencies may be missing"
            echo "Install with: brew install cairo pango gdk-pixbuf libffi"
            echo "Continue anyway? (y/N)"
            read -r response
            if [[ ! "$response" =~ ^[Yy]$ ]]; then
                exit 1
            fi
        fi
    fi

    echo_success "Dependencies check passed"
}

install_pdf_dependencies() {
    echo_info "Installing PDF generation dependencies..."
    "$VENV/bin/pip" install -r "$ROOT_DIR/requirements.txt"
    echo_success "Dependencies installed"
}

generate_complete_pdf() {
    echo_info "Generating complete documentation PDF..."
    cd "$ROOT_DIR"
    ENABLE_PDF_EXPORT=1 "$VENV/bin/mkdocs" build --config-file mkdocs.local.yml

    if [ -f "$ROOT_DIR/site/pdf/n8n-docs.pdf" ]; then
        echo_success "Complete PDF generated: site/pdf/n8n-docs.pdf"
        return 0
    else
        echo_error "Failed to generate complete PDF"
        return 1
    fi
}

generate_section_pdfs() {
    echo_info "Generating PDFs by section (using navigation structure)..."
    cd "$ROOT_DIR"
    ENABLE_PDF_EXPORT=1 python "$SCRIPTS_DIR/generate_section_pdfs.py"
}

generate_folder_pdfs() {
    echo_info "Generating PDFs by folder (simple approach)..."
    cd "$ROOT_DIR"
    ENABLE_PDF_EXPORT=1 python "$SCRIPTS_DIR/generate_folder_pdfs.py"
}

show_help() {
    echo "Usage: $0 [OPTION]"
    echo "Generate PDF documentation for n8n"
    echo ""
    echo "Options:"
    echo "  complete    Generate single PDF with all documentation"
    echo "  sections    Generate separate PDFs by logical sections"
    echo "  folders     Generate separate PDFs by folder structure"
    echo "  install     Install PDF generation dependencies"
    echo "  help        Show this help message"
    echo ""
    echo "Environment variables:"
    echo "  ENABLE_PDF_EXPORT=1  Required to generate PDFs"
}

main() {
    case "${1:-}" in
        "complete")
            check_dependencies
            generate_complete_pdf
            ;;
        "sections")
            check_dependencies
            generate_section_pdfs
            ;;
        "folders")
            check_dependencies
            generate_folder_pdfs
            ;;
        "install")
            install_pdf_dependencies
            ;;
        "help"|"--help"|"-h")
            show_help
            ;;
        "")
            echo_info "n8n Documentation PDF Generator"
            echo ""
            echo "Choose generation method:"
            echo "1) Complete documentation (single PDF)"
            echo "2) By sections (multiple PDFs by topic)"
            echo "3) By folders (multiple PDFs by directory)"
            echo "4) Install dependencies"
            echo "5) Help"
            echo ""
            read -p "Select option (1-5): " choice

            case $choice in
                1) main "complete" ;;
                2) main "sections" ;;
                3) main "folders" ;;
                4) main "install" ;;
                5) main "help" ;;
                *) echo_error "Invalid option"; exit 1 ;;
            esac
            ;;
        *)
            echo_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
