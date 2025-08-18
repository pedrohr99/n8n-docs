README-local — instrucciones para desarrollo local

Este archivo contiene instrucciones específicas para ejecutar y previsualizar la documentación en un entorno local sin modificar el `README.md` upstream.

Requisitos
- macOS con Python 3.8+ instalado
- `uv` (recomendado) o `python -m venv` para crear el virtualenv

Pasos rápidos
1. Crear el entorno virtual (recomendado con `uv`):

   uv venv

2. Activar el virtualenv:

   source .venv/bin/activate

3. Instalar dependencias del proyecto dentro del virtualenv:

   .venv/bin/pip install -r requirements.txt
   .venv/bin/pip install mkdocs-material

4. Iniciar la vista previa local (script proporcionado):

   ./scripts/serve.sh

Qué hay en este fork
- `mkdocs.local.yml`: configuración local con pequeños ajustes (no modifica `mkdocs.yml` usado por upstream).
- `scripts/serve.sh`: activa `.venv` y arranca MkDocs con `mkdocs.local.yml` y `--strict`.
- `.venv/` añadido a `.gitignore` para evitar que el entorno virtual se suba al repositorio.

Buenas prácticas
- Mantén tus cambios locales en ramas de trabajo y evita editar `mkdocs.yml` directamente a menos que quieras que se propague upstream.
- `mkdocs.local.yml` permite ajustar la configuración sólo en tu entorno local y reduce conflictos con el repositorio original.

Si quieres, puedo:
- Añadir una referencia breve a este archivo en el `README.md` (como nota para colaboradores del fork).
- Incluir instrucciones para Windows o Docker.
