TARGET_CMD="__TARGET_CMD__"
WRAPPER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

strip_path_entry() {
    local entry_to_remove="$1"
    local original_path="$2"
    local filtered_path=""
    local path_entry
    local IFS=':'

    for path_entry in $original_path; do
        if [ -n "$path_entry" ] && [ "$path_entry" != "$entry_to_remove" ]; then
            if [ -n "$filtered_path" ]; then
                filtered_path="$filtered_path:$path_entry"
            else
                filtered_path="$path_entry"
            fi
        fi
    done

    printf '%s' "$filtered_path"
}

find_project_root() {
    local dir
    dir="$(pwd)"
    while [ "$dir" != "/" ]; do
        if [ -f "$dir/.env" ] || [ -f "$dir/Dockerfile" ] || [ -f "$dir/bin/activate" ]; then
            printf '%s' "$dir"
            return 0
        fi
        dir="$(dirname "$dir")"
    done
    printf '%s' "$(pwd)"
}

PROJECT_ROOT="$(find_project_root)"
INVOKE_DIR="$(pwd)"
cd "$PROJECT_ROOT"

if [ -f "$PROJECT_ROOT/.env" ]; then
    set -a
    source "$PROJECT_ROOT/.env"
    set +a
fi

LOCAL_ROOT="${LOCAL_ROOT:-$PROJECT_ROOT}"
CONTAINER_ROOT="${CONTAINER_ROOT:-/var/www/html}"
SERVICE_NAME="${SERVICE_NAME:-app}"

SKIP_DOCKER=0
for arg in "$@"; do
    # Se l'argomento è un percorso assoluto esistente e NON è in LOCAL_ROOT
    # (es. tools dell'IDE come PhpStorm o language servers in /mnt/c/...),
    # evitiamo di usare Docker poichè il file non sarebbe accessibile.
    if [[ "$arg" == /* ]] && { [ -e "$arg" ] || [ -L "$arg" ]; } && [[ "$arg" != "$LOCAL_ROOT"* ]]; then
        SKIP_DOCKER=1
        break
    fi
done

if [ "$SKIP_DOCKER" -eq 1 ]; then
    cd "$INVOKE_DIR"

    # Estendiamo il PATH perché spesso gli IDE lanciano i processi con un ambiente
    # minimo, rendendo impossibile trovare i binari di sistema su NixOS.
    EXTENDED_PATH="$PATH:/run/current-system/sw/bin:/etc/profiles/per-user/$(whoami)/bin:$HOME/.nix-profile/bin:/nix/var/nix/profiles/default/bin"

    while IFS= read -r cmd_path; do
        if [ "$(readlink -f "$cmd_path")" != "$(readlink -f "${BASH_SOURCE[0]}")" ]; then
            exec "$cmd_path" "$@"
        fi
    done < <(PATH="$EXTENDED_PATH" type -a -P "$TARGET_CMD" 2>/dev/null)

    echo "[Error] Fallback: unable to find original '$TARGET_CMD'." >&2
    exit 1
fi

_venv_default="$PROJECT_ROOT/bin/activate"
VENV_PATH="${VENV_PATH:-$_venv_default}"
CONTAINER_WORKDIR="${INVOKE_DIR//$LOCAL_ROOT/$CONTAINER_ROOT}"
if [[ "$VENV_PATH" != /* ]]; then
    VENV_PATH="$PROJECT_ROOT/$VENV_PATH"
fi

if [ -f "$VENV_PATH" ]; then
    source "$VENV_PATH"

    if alias "$TARGET_CMD" >/dev/null 2>&1; then
        alias_body="$(alias "$TARGET_CMD")"
        alias_body="${alias_body#*=}"
        alias_body="${alias_body#\'}"
        alias_body="${alias_body%\'}"

        alias_body="$(printf '%s' "$alias_body" | sed 's/-it\b/-i/g; s/-ti\b/-i/g')"
        alias_body="$(printf '%s' "$alias_body" | sed "s#--workdir [^ ]*#--workdir $CONTAINER_WORKDIR#g")"

        translated_args=()
        for arg in "$@"; do
            translated_args+=("${arg//$LOCAL_ROOT/$CONTAINER_ROOT}")
        done
        eval "$alias_body $(printf '%q ' "${translated_args[@]}")"
    else
        echo "[Error] Alias '$TARGET_CMD' non trovato dopo l'attivazione di $VENV_PATH." >&2
        exit 1
    fi
else
    translated_args=()
    for arg in "$@"; do
        translated_args+=("${arg//$LOCAL_ROOT/$CONTAINER_ROOT}")
    done

    if [ "$(docker compose ps -q "$SERVICE_NAME" 2>/dev/null)" ] && [ "$(docker ps -q -f id=$(docker compose ps -q "$SERVICE_NAME"))" ]; then
        :
    else
        docker compose up -d >&2
    fi

    docker compose exec -i -T --workdir="$CONTAINER_WORKDIR" "$SERVICE_NAME" "$TARGET_CMD" "${translated_args[@]}"
fi
