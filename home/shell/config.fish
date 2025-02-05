fish_add_path $HOME/.config/composer/vendor/bin "/mnt/c/Users/Maicol/AppData/Local/Programs/Microsoft VS Code/bin" /mnt/c/Windows

# X410
export DISPLAY=localhost:0.0

# set -U fish_greeting

#
# Async Prompt
#

# Setup the synchronous prompt that is displayed immediately while the async
# prompt is loading.
# set -g STARSHIP_CONFIG_MINIMAL $HOME/.config/starship-minimal.toml

# function fish_prompt_loading_indicator
#   STARSHIP_CONFIG=$STARSHIP_CONFIG_MINIMAL starship prompt
# end

# function fish_prompt_right_loading_indicator
#   STARSHIP_CONFIG=$STARSHIP_CONFIG_MINIMAL starship prompt --right
# end

# Disable async prompt
# set -g async_prompt_enable 0

# Fix incompatibility with zoxide. Source: https://github.com/acomagu/fish-async-prompt/issues/77#issuecomment-2132709455
function fish_focus_in --on-event fish_focus_in
    __async_prompt_fire
    # commandline -f paint  # Not sure whether this helps or hurts.
end

function fish_right_prompt
    rpoc_time
end
