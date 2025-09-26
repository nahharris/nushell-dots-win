export alias lg = lazygit
export alias ez = eza -halF --color=auto --icons=always --group-directories-first --binary
export alias fzf = fzf --layout=reverse --border=rounded --height=60% --padding=2% --preview="bat {} --style=numbers --color=always"
export alias batrg = batgrep --pager=$"($env.PAGER)"