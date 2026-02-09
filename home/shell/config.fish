fish_add_path $HOME/.config/composer/vendor/bin "/mnt/c/Users/Maicol/AppData/Local/Programs/Microsoft VS Code/bin" /mnt/c/Windows

# X410
export DISPLAY=localhost:0.0

function fish_right_prompt
    rpoc_time
end

# Enable custom Laravel venv
if test -f artisan && test -f bin/activate.fish
    # Already checked for file existence, so this should be safe.
    # @fish-lsp-disable-next-line 1004
    source bin/activate.fish
end

# Disable venv when not in a Laravel project
# Check if current path is inside $VIRTUAL_ENV
# if test -n "$VIRTUAL_ENV" && not string match -q "$PWD" "$VIRTUAL_ENV"
#     deactivate
# end

set sponge_purge_only_on_exit true

# If kubectl is installed
if type -q kubectl
    # This needs to be added before "function ... --wraps kubectl"
    kubectl completion fish | source

    # adds alias for "kubectl" to "kubecolor" with completions
    function kubectl --wraps kubectl
        command kubecolor $argv
    end

    # adds alias for "k" to "kubecolor" with completions
    function k --wraps kubectl
        command kubecolor $argv
    end

    # reuse "kubectl" completions on "kubecolor"
    function kubecolor --wraps kubectl
        command kubecolor $argv
    end
end
