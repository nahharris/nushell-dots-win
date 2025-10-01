# Retrieve the theme settings
export def main [] {
    # Ayu theme colors
    # Base colors
    let red = '#f07078'
    let orange = '#f19618'
    let yellow = '#e6c446'
    let green = '#b8cc52'
    let cyan = '#95e5cb'
    let blue = '#36a3d9'

    # Bright/light variations
    let light_red = '#ff6565'
    let bright_red = '#ff3333'
    let light_cyan = '#c7fffc'

    # Grayscale and other
    let white = '#ffffff'
    let pure_red = '#FF0000'
    let dark_gray = 'dark_gray'
    let dark_gray_hints = '#323232'

    # UI colors
    let foreground = '#e5e1cf'
    let background = '#0e141900'
    let cursor = $orange

    return {
        binary: $red
        block: $blue
        cell-path: $white
        closure: $cyan
        custom: $white
        duration: $yellow
        float: $light_red
        glob: $white
        int: $red
        list: $cyan
        nothing: $bright_red
        range: $yellow
        record: $cyan
        string: $green

        bool: {|| if $in { $light_cyan } else { $yellow } }

        date: {|| (date now) - $in |
            if $in < 1hr {
                { fg: $bright_red attr: 'b' }
            } else if $in < 6hr {
                $bright_red
            } else if $in < 1day {
                $yellow
            } else if $in < 3day {
                $green
            } else if $in < 1wk {
                { fg: $green attr: 'b' }
            } else if $in < 6wk {
                $cyan
            } else if $in < 52wk {
                $blue
            } else { $dark_gray }
        }

        filesize: {|e|
            if $e == 0b {
                $white
            } else if $e < 1mb {
                $cyan
            } else {{ fg: $blue }}
        }

        shape_and: { fg: $red attr: 'b' }
        shape_binary: { fg: $red attr: 'b' }
        shape_block: { fg: $blue attr: 'b' }
        shape_bool: $light_cyan
        shape_closure: { fg: $cyan attr: 'b' }
        shape_custom: $green
        shape_datetime: { fg: $cyan attr: 'b' }
        shape_directory: $cyan
        shape_external: $cyan
        shape_external_resolved: $light_cyan
        shape_externalarg: { fg: $green attr: 'b' }
        shape_filepath: $cyan
        shape_flag: { fg: $blue attr: 'b' }
        shape_float: { fg: $light_red attr: 'b' }
        shape_garbage: { fg: $white bg: $pure_red attr: 'b' }
        shape_glob_interpolation: { fg: $cyan attr: 'b' }
        shape_globpattern: { fg: $cyan attr: 'b' }
        shape_int: { fg: $red attr: 'b' }
        shape_internalcall: { fg: $cyan attr: 'b' }
        shape_keyword: { fg: $red attr: 'b' }
        shape_list: { fg: $cyan attr: 'b' }
        shape_literal: $blue
        shape_match_pattern: $green
        shape_matching_brackets: { attr: 'u' }
        shape_nothing: $bright_red
        shape_operator: $yellow
        shape_or: { fg: $red attr: 'b' }
        shape_pipe: { fg: $red attr: 'b' }
        shape_range: { fg: $yellow attr: 'b' }
        shape_raw_string: { fg: $white attr: 'b' }
        shape_record: { fg: $cyan attr: 'b' }
        shape_redirection: { fg: $red attr: 'b' }
        shape_signature: { fg: $green attr: 'b' }
        shape_string: $green
        shape_string_interpolation: { fg: $cyan attr: 'b' }
        shape_table: { fg: $blue attr: 'b' }
        shape_vardecl: { fg: $blue attr: 'u' }
        shape_variable: $red

        foreground: $foreground
        background: $background
        cursor: $cursor

        empty: $blue
        header: { fg: $green attr: 'b' }
        hints: $dark_gray_hints
        leading_trailing_space_bg: { attr: 'n' }
        row_index: { fg: $green attr: 'b' }
        search_result: { fg: $bright_red bg: $white }
        separator: $white
    }
}

# Update the Nushell configuration
export def --env "set color_config" [] {
    $env.config.color_config = (main)
}

# Update terminal colors
export def "update terminal" [] {
    let theme = (main)

    # Set terminal colors
    let osc_screen_foreground_color = '10;'
    let osc_screen_background_color = '11;'
    let osc_cursor_color = '12;'
        
    $"
    (ansi -o $osc_screen_foreground_color)($theme.foreground)(char bel)
    (ansi -o $osc_screen_background_color)($theme.background)(char bel)
    (ansi -o $osc_cursor_color)($theme.cursor)(char bel)
    "
    # Line breaks above are just for source readability
    # but create extra whitespace when activating. Collapse
    # to one line and print with no-newline
    | str replace --all "
" ''
    | print -n $"($in)"
}

export module activate {
    export-env {
        set color_config
        update terminal
    }
}

# Activate the theme when sourced
use activate
