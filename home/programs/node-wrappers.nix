{ pkgs, lib, ... }: let
  wrapperCommands = [ "node" "npm" "pnpm" "yarn" "npx" ];

  mkNodeWrapperScript = targetCmd:
    pkgs.writeShellScript targetCmd ''
      TARGET_CMD="${targetCmd}"
      WRAPPER_DIR="$(cd "$(dirname "''${BASH_SOURCE[0]}")" && pwd)"

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

      if [ -f .env ]; then
          set -a
          source .env
          set +a
      fi

      LOCAL_ROOT="''${LOCAL_ROOT:-$(pwd)}"
      CONTAINER_ROOT="''${CONTAINER_ROOT:-/var/www/html}"
      SERVICE_NAME="''${SERVICE_NAME:-app}"
      VENV_PATH="''${VENV_PATH:-bin/activate}"

      if [ -f "$VENV_PATH" ]; then
          echo "[Info] Activating virtual environment at $VENV_PATH..." >&2
          source "$VENV_PATH"

            if alias "$TARGET_CMD" >/dev/null 2>&1; then
              alias_body="$(alias "$TARGET_CMD")"
              alias_body="''${alias_body#*=}"
              alias_body="''${alias_body#\'}"
              alias_body="''${alias_body%\'}"

                if [ -n "$LOCAL_ROOT" ] && [[ "$alias_body" == *"--workdir "*"$LOCAL_ROOT"* ]]; then
                  local_root_escaped="$(printf '%s' "$LOCAL_ROOT" | sed 's/[.[\*^$()+?{|]/\\&/g')"
                  alias_body="$(printf '%s' "$alias_body" | sed "s#--workdir \([^ ]*\)$local_root_escaped#--workdir \\1#g")"
                fi

              eval "$alias_body \"$@\""
            else
              echo "[Error] Alias '$TARGET_CMD' non trovato dopo l'attivazione di $VENV_PATH." >&2
              exit 1
            fi
      else
          echo "[Info] Fallback to Docker Compose..." >&2

          translated_args=()
          for arg in "$@"; do
              translated_args+=("''${arg//$LOCAL_ROOT/$CONTAINER_ROOT}")
          done

          if [ "$(docker compose ps -q "$SERVICE_NAME" 2>/dev/null)" ] && [ "$(docker ps -q -f id=$(docker compose ps -q "$SERVICE_NAME"))" ]; then
              :
          else
              echo "[Info] Starting Docker Compose services..." >&2
              docker compose up -d >&2
          fi

          docker compose exec -T "$SERVICE_NAME" "$TARGET_CMD" "''${translated_args[@]}"
      fi
    '';

  nodeWrappersPackage = pkgs.runCommand "node-wrappers" {} ''
    mkdir -p "$out/bin/node-wrappers"

    ${lib.concatMapStringsSep "\n" (targetCmd: ''
      ln -s ${mkNodeWrapperScript targetCmd} "$out/bin/node-wrappers/${targetCmd}"
    '') wrapperCommands}
  '';
in {
  home.packages = [ nodeWrappersPackage ];
}