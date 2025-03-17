# Commandline File Explorer with CD support in Nushell
def --env yy [...args] {
	let tmp = (mktemp -t "yazi-cwd.XXXXXX")
	yazi ...$args --cwd-file $tmp
	let cwd = (open $tmp)
	if $cwd != "" and $cwd != $env.PWD {
		cd $cwd
	}
	rm -fp $tmp
}

# An `fzf` alias that uses `fd` as file search engine
def fzfd [
    path?: string # Path to start the search
]: nothing -> string {
    let res = if $path != null and ($path | str trim) != "" {
        fd --hidden --follow --exclude .git --ignore-file ~/.fzfignore . $"($path)"| fzf
    } else {
        fd --hidden --follow --exclude .git --ignore-file ~/.fzfignore | fzf
    }


    if ($res | str trim) == "" {
        " "
    } else {
        $res
    }
}

# Gets a token from an string that contains the i-th char
# If the index is one char past a word, this word is collected
# If the index isn't over a word nor one char past the word, an empty string is returned
def get-token-at-pos [
    # The index of the char
    i: int
]: string -> string {
    let input = $in
    let str = ($input | split chars)
    mut i = $i

    if ($input | str length) == 0 {
        return ""
    }

    if $i >= ($input | str length) {
        $i -= 1
    }

    let word = if ($str | get $i) == " " {
        # The index is in the void
        if $i > 0 and ($str | get ($i - 1)) == " " or $i == 0 {
            print "void"

            ""

        # The index is one past a word
        } else {
            mut $j = $i - 1

            while $j > 0 and ($str | get $j) != ' ' {
                $j -= 1
            }

            let j = $j

            ($input | str substring $j..$i) | str trim
        }
    # The index is in the middle of a word
    } else {
        mut $j = $i

        while $j > 0 and ($str | get $j) != ' ' {
            $j -= 1
        }

        while $i < ($input | str length) and ($str | get $i) != ' ' {
            $i += 1
        }

        let j = $j

        ($input | str substring $j..$i) | str trim
    }

    $word
}

def "cargo search" [ query: string, --limit=10] {
    ^cargo search $query --limit $limit
    | lines
    | each {
        |line| if ($line | str contains "#") {
            $line | parse --regex '(?P<name>.+) = "(?P<version>.+)" +# (?P<description>.+)'
        } else {
            $line | parse --regex '(?P<name>.+) = "(?P<version>.+)"'
        }
    }
    | flatten
}

def ___package_info [ header: string, description: string ] {
    $header ++ " "
    | parse --regex '(?P<name>.+)/(?P<distro>\S+) (?P<version>\S+) (?P<arch>\S+) (?P<installed>.+)?'
    | insert description $description
}

def ___build_apt_table [] {
    lines
    | where ($it | str length) > 0
    | reduce --fold [] { |$it, $acc|
        if ($acc | is-not-empty) and ($acc | last | length) < 2 {
            let last = ($acc | last)
            let init = ($acc | drop)
            $init | append [[($last | last), $it]]
        } else {
            $acc | append [[$it]]
        }
    }
    | each { |$it|
        ___package_info $it.0 $it.1
    }
    | reduce {|$it, $acc| $acc | append $it }
}

# Improved version of apt search that uses nushell structured output
def "apt find" [
    package: string, # The package to search for
    --json (-j) # Shows the output as a json
] {
    let res = (apt search $package) | ___build_apt_table

    if $json {
        $res | to json
    } else {
        $res
    }
}

def "nu-complete webtty shells" [] {
    open /etc/shells
    | lines
    | filter {|l| not ($l | str trim | str starts-with '#') }
}

# Launches a webclient for a local shell
def "webtty" [
    --port(-p): number = 8765,
    --shell(-s): string@"nu-complete webtty shells"
] {
    ttyd -W -w ~ -p $port -t 'fontFamily="FiraCode Nerd Font"' -t 'theme={
        "background": "#1E1E2E",
        "black": "#45475A",
        "blue": "#89B4FA",
        "brightBlack": "#585B70",
        "brightBlue": "#89B4FA",
        "brightCyan": "#94E2D5",
        "brightGreen": "#A6E3A1",
        "brightPurple": "#F5C2E7",
        "brightRed": "#F38BA8",
        "brightWhite": "#A6ADC8",
        "brightYellow": "#F9E2AF",
        "cursorColor": "#F5E0DC",
        "cyan": "#94E2D5",
        "foreground": "#CDD6F4",
        "green": "#A6E3A1",
        "name": "Catppuccin Mocha",
        "purple": "#F5C2E7",
        "red": "#F38BA8",
        "selectionBackground": "#585B70",
        "white": "#BAC2DE",
        "yellow": "#F9E2AF"
    }' (if ($shell == null or not $shell in (nu-complete webtty shells)) { $env.SHELL } else { $shell })
}

# Gets a list of all installed packages from nala, home-manager and cargo
def "sys packages" [
    --full (-f)                         # Shows the full list of packages including versions
] {
    let nala = (nala list -N
        | rg ^\w
        | if ($full) { echo $in } else { sd " .*" "" }
        | lines
        | uniq
    )

    let home = (home-manager packages
        | if ($full) { echo $in } else { sd -- "-[0-9][0-9.]*(-man|-xxd)?$" "" }
        | lines
        | uniq
    )

    let cargo = (cargo install --list
        | rg "^[a-z]"
        | if ($full) {echo $in} else { sd " v.*$" "" }
        | lines
    )

    {
        nala: $nala,
        home-manager: $home,
        cargo: $cargo
    }
}

# Uses bat to display help pages with colors and paging
def help [
    ...cmd: string # The command to get help from (must provide the `--help` flag)
] {
    if ($cmd != []) {
        nu -c $"($cmd | str join ' ') --help" | bat --language=help --style=plain
    } else {
        $in | bat --language=help --style=plain
    }
}

# Combines the power of fd and bat to search for files and display them with colors
def batfd [
    --hidden(-H)      # Include hidden directories and files in the search results
    --glob(-g)        # Uses glob in the pattern
    --regex           # Overrides --glob to use regex in the pattern
    pattern?: string  # The search pattern, can be a regex or glob (--glob)
    ...path: string
] {
    fd $pattern ...$path -c always | bat -p
}

def "nu-complete gldr list" [] {
  ^tldr --list
  | lines
}

# Integration between tldr and glow
def gldr [
    ...page: string@"nu-complete gldr list"
] {
    tldr ($page | str join "-") --raw | glow
}

def "pkg search" [
    query: string
] {
    ^apt-cache search $query
    | parse --regex '(?P<name>\S+) - (?P<description>.+)'
}

def "pkg details" [
    package: string
] {
    let details = (^apt-cache show $package) | str replace --regex --multiline '\n\n[\s\S]*' ''

    let tags = if ($details | str contains Tag ) {
        $details
        | str replace --regex --multiline '(Package:[\s\S]*Tag: )' ''
        | str replace --regex --multiline 'Section:[\s\S]*' ''
        | lines
        | each {|line| $line | split row ',' }
        | flatten
        | filter {|line| not ($line | is-empty ) }
        | each {|item| $item | str trim }
    } else {
        []
    }

    let depends = if ($details | str contains Depends ) {
        $details
        | str replace --regex --multiline '(Package:[\s\S]*Depends: )' ''
        | str replace --regex --multiline '\n[\s\S]*' ''
        | lines
        | each {|line| $line | split row ',' }
        | flatten
        | filter {|line| not ($line | is-empty ) }
        | each {|item| $item | str trim }
    } else {
        []
    }

    let recommends = if ($details | str contains Recommends ) {
        $details
        | str replace --regex --multiline '(Package:[\s\S]*Recommends: )' ''
        | str replace --regex --multiline '\n[\s\S]*' ''
        | lines
        | each {|line| $line | split row ',' }
        | flatten
        | filter {|line| not ($line | is-empty ) }
        | each {|item| $item | str trim }
    } else {
        []
    }

    let provides = if ($details | str contains Provides ) {
        $details
        | str replace --regex --multiline '(Package:[\s\S]*Provides: )' ''
        | str replace --regex --multiline '\n[\s\S]*' ''
        | lines
        | each {|line| $line | split row ',' }
        | flatten
        | filter {|line| not ($line | is-empty ) }
        | each {|item| $item | str trim }
    } else {
        []
    }

    let replaces = if ($details | str contains Replaces ) {
        $details
        | str replace --regex --multiline '(Package:[\s\S]*Replaces: )' ''
        | str replace --regex --multiline '\n[\s\S]*' ''
        | lines
        | each {|line| $line | split row ',' }
        | flatten
        | filter {|line| not ($line | is-empty ) }
        | each {|item| $item | str trim }
    } else {
        []
    }

    let suggests = if ($details | str contains Suggests ) {
        $details
        | str replace --regex --multiline '(Package:[\s\S]*Suggests: )' ''
        | str replace --regex --multiline '\n[\s\S]*' ''
        | lines
        | each {|line| $line | split row ',' }
        | flatten
        | filter {|line| not ($line | is-empty ) }
        | each {|item| $item | str trim }
    } else {
        []
    }

    let breaks = if ($details | str contains Breaks ) {
        $details
        | str replace --regex --multiline '(Package:[\s\S]*Breaks: )' ''
        | str replace --regex --multiline '\n[\s\S]*' ''
        | lines
        | each {|line| $line | split row ',' }
        | flatten
        | filter {|line| not ($line | is-empty ) }
        | each {|item| $item | str trim }
    } else {
        []
    }

    let conflicts = if ($details | str contains Conflicts ) {
        $details
        | str replace --regex --multiline '(Package:[\s\S]*Conflicts: )' ''
        | str replace --regex --multiline '\n[\s\S]*' ''
        | lines
        | each {|line| $line | split row ',' }
        | flatten
        | filter {|line| not ($line | is-empty ) }
        | each {|item| $item | str trim }
    } else {
        []
    }

    let predepends = if ($details | str contains Pre-Depends ) {
        $details
        | str replace --regex --multiline '(Package:[\s\S]*Pre-Depends: )' ''
        | str replace --regex --multiline '\n[\s\S]*' ''
        | lines
        | each {|line| $line | split row ',' }
        | flatten
        | filter {|line| not ($line | is-empty ) }
        | each {|item| $item | str trim }
    } else {
        []
    }

    let details = $details
    | parse --regex '(?P<key>\S+): (?P<value>.+)'
    | reduce --fold {} {|it, acc|
        $acc
        | insert ($it.key) ($it.value) }

    let details = if ($tags | is-empty) {
        $details
    } else {
        $details | update Tag $tags
    }

    let details = if ($depends | is-empty) {
        $details
    } else {
        $details | update Depends $depends
    }

    let details = if ($suggests | is-empty) {
        $details
    } else {
        $details | update Suggests $suggests
    }

    let details = if ($breaks | is-empty) {
        $details
    } else {
        $details | update Breaks $breaks
    }

    let details = if ($recommends | is-empty) {
        $details
    } else {
        $details | update Recommends $recommends
    }

    let details = if ($provides | is-empty) {
        $details
    } else {
        $details | update Provides $provides
    }

    let details = if ($replaces | is-empty) {
        $details
    } else {
        $details | update Replaces $replaces
    }

    let details = if ($conflicts | is-empty) {
        $details
    } else {
        $details | update Conflicts $conflicts
    }

    let details = if ($predepends | is-empty) {
        $details
    } else {
        $details | update Pre-Depends $predepends
    }

    $details
}

def --env "dotenv" [
    file: string = ".env"
] {
    open $file
    | lines
    | split column '='
    | transpose --header-row
    | into record
    | load-env
}

def "git graph" [
    --help(-h) # Shows the help page
] {
    if $help {
        help git-graph
    } else {
        ^git-graph --color always --no-pager --style round --format "[%cs] %h %d %s %n" --wrap none | bat -p 
    }
}

# Opens the nushell bin config file in the default editor
def "config bin" [] {
    nu -c $"($env.EDITOR) ($nu.default-config-dir)/bin.nu"
}

# Opens the nushell aliases config file in the default editor
def "config aliases" [] {
    nu -c $"($env.EDITOR) ($nu.default-config-dir)/aliases.nu"
}
