fish_add_path $HOME/.config/composer/vendor/bin "/mnt/c/Users/Maicol/AppData/Local/Programs/Microsoft VS Code/bin" /mnt/c/Windows

# X410
export DISPLAY=localhost:0.0

function fish_right_prompt
    rpoc_time
end

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
