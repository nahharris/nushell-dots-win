# env.nu
#
# Installed by:
# version = "0.102.0"
#
# Previously, environment variables were typically configured in `env.nu`.
# In general, most configuration can and should be performed in `config.nu`
# or one of the autoload directories.
#
# This file is generated for backwards compatibility for now.
# It is loaded before config.nu and login.nu
#
# See https://www.nushell.sh/book/configuration.html
#
# Also see `help config env` for more options.
#
# You can remove these comments if you want or leave
# them for future reference.
$env.EDITOR = (which nvim | get 0 | get path)
$env.HOME = "C:/Users/jorge"

$env.FZF_DEFAULT_COMMAND = $'fd --strip-cwd-prefix --hidden --follow --exclude .git --ignore-file ~/.fzfignore'
$env.FZF_DEFAULT_OPTS = $'--layout=reverse --border=rounded --height=60% --padding=2% --preview="rsp {}" --bind=shift-up:preview-up,shift-down:preview-down,shift-right:preview-bottom,shift-left:preview-top,alt-w:toggle-preview-wrap'
$env.FZF_CTRL_T_COMMAND = $env.FZF_DEFAULT_COMMAND

$env.CARAPACE_BRIDGES = 'zsh,fish,bash,inshellisense' # optional
$env.LS_COLORS = (vivid generate ayu)
    
$env.EDITOR = "nvim"
$env.PAGER = "bat --plain"
$env.DELTA_PAGER = "bat --plain"
$env.MANPAGER = "sh -c 'col -bx | bat -l man -p'"
$env.MANROFFOPT = "-c"
