--
--  Copyright (C) 2017 Ivan Čukić <ivan.cukic(at)kde.org>
--
--  This program is free software: you can redistribute it and/or modify
--  it under the terms of the GNU General Public License as published by
--  the Free Software Foundation, either version 3 of the License, or
--  (at your option) any later version.
--
--  This program is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY; without even the implied warranty of
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--  GNU General Public License for more details.
--
--  You should have received a copy of the GNU General Public License
--  along with this program.  If not, see <http://www.gnu.org/licenses/>.
--

config =
    buffer: {}
    prefix: "//>"
    comment: "//"

    latex_start_char: "▮"
    latex_open_char: "◀"
    latex_close_char: "▶"

    bold_marker: "^"
    normal_marker: "normal"
    important_marker: "important"
    unimportant_marker: "fade"


-- Utility functions
export utils = {
    trim: (s) ->
        return s\gsub("^%s*(.-)%s*$", "%1")

    for_each: (items, fun) ->
        for item in items
            fn(item)

    consecutive_pairs: (items, last) ->
        result = {}

        items_count = #items

        for index = 1, items_count
            table.insert result, {
                    first:  items[index]
                    second: if index + 1 >= items_count then last else items[index + 1]
                }

        return result
    }



-- Private implementation
export d = {
    -- enum state
    normal_state: 0
    important_state: 1
    unimportant_state: 2

    auto_font_size: false

    state: normal_state
    gobble: 0
    max_line_length: 0
    enable_debug: false
    enable_debug_full: false

    bold_pattern: "^" .. config.prefix .. "[ " .. config.bold_marker .. "]*$"

    latex: (command, body) ->
        return config.latex_start_char .. command .. config.latex_open_char .. body .. config.latex_close_char

    debug: (message) ->
        if d.enable_debug
            texio.write_nl("othercoder: " .. message)

    process_first_line: (current_line) ->
        -- Do we have gobble bar?
        d.gobble = current_line\find "|"
        if d.gobble == nil then
            d.gobble = 0
        else
            d.gobble -= 1

        d.debug("Detected gobble while processing the first line: " .. d.gobble)
        d.debug(" -> " .. current_line)

        -- TODO: Something else?
        return ""


    process_markup_line: (current_line) ->
        -- This line should be ignored, this is a markup
        -- for Other Coder
        if current_line\match config.normal_marker then
            d.state = d.normal_state

        elseif current_line\match config.important_marker then
            d.state = d.important_state

        elseif current_line\match config.unimportant_marker then
            d.state = d.unimportant_state

        return ""


    process_normal_line: (current_line, next_line) ->

        if d.max_line_length < string.len(current_line) then
            d.max_line_length = string.len(current_line)

        -- Checking for in-line markup
        current_line_state = d.state
        current_line_markup_text = ""
        current_line = current_line\gsub config.prefix .. "(.*)",
                                         (s) -> current_line_markup_text = utils.trim s


        if current_line_markup_text\match config.normal_marker then
            current_line_state = d.normal_state

        elseif current_line_markup_text\match config.important_marker then
            current_line_state = d.important_state

        elseif current_line_markup_text\match config.unimportant_marker then
            current_line_state = d.unimportant_state



        -- Replace ::: with ellipsis
        current_line = current_line\gsub ":::", d.latex("othercoderUnimportant", "⋯")

        -- Adding the notation number to the current line
        current_line = current_line\gsub "// <([0-9])>",
                                         d.latex("othercoderCircled", "%1")



        -- Checking for barred comments
        current_comment_text = ""

        current_line = current_line\gsub "// |(.*)",
                                         (s) -> current_comment_text = utils.trim s

        -- Backticks are used to denote texttt
        current_comment_text = current_comment_text\gsub "`([^`]*)`",
                                                         d.latex("texttt", "%1")

        -- Circled numbers in the barred comment
        current_comment_text = current_comment_text\gsub "<([0-9])>",
                                                         d.latex("othercoderCircled", "%1")

        -- Replacing the barred comment markup with LaTeX commands
        current_line = current_line\gsub "// |(.*)",
                                         d.latex("othercoderBarred", "") .. " " .. d.latex("sffamily", " " .. current_comment_text)

        output = ""

        if d.state == d.unimportant_state then
            current_line = current_line\gsub "(%s*)(.*)",
                                             "%1" .. d.latex("othercoderUnimportant", "%2")
            output ..= current_line

        elseif d.state == d.important_state then
            current_line = current_line\gsub "(%s*)(.*)",
                                             "%1" .. d.latex("othercoderImportant", "%2")
            output ..= current_line

        else
            if next_line\match d.bold_pattern then
                is_bold = false

                for ci = 1, #current_line do
                    c = current_line\sub(ci, ci)
                    m = next_line\sub(ci, ci)

                    if not is_bold and m == "^" then
                        -- we are using Palochka for command start
                        output ..= config.latex_start_char .. "othercoderImportant" .. config.latex_open_char  -- going bold
                        is_bold = true

                    elseif is_bold and not (m == "^") then
                        output ..= config.latex_close_char -- not bold anymore
                        is_bold = false

                    output ..= c

                if is_bold then
                    output ..= consig.latex_close_char -- not bold anymore

            else
                -- We do not have the markup
                output ..= current_line

        output ..= "\r"
        return output






    process_line: (current_line, next_line) ->
        if current_line\match("^" .. config.prefix)
            return d.process_markup_line current_line

        else
            return d.process_normal_line(current_line, next_line)


    process_input: (lines) ->
        -- reset state
        d.state           = d.normal_state
        d.gobble          = 0
        d.max_line_length = 0

        result = ""

        for index, pair in ipairs utils.consecutive_pairs lines, ""
            current_line = pair.first
            next_line    = pair.second

            if index == 1 and current_line\match "^" .. config.prefix then
                result ..= d.process_first_line current_line
            else
                result ..= d.process_line pair.first, pair.second

        font_size = ""

        if d.auto_font_size then
            d.max_line_length -= d.gobble

            if d.max_line_length < 40
                font_size = "\\large"
            elseif d.max_line_length < 45
                font_size = "\\normalsize"
            elseif d.max_line_length < 55
                font_size = "\\footnotesize"
            elseif d.max_line_length < 60
                font_size = "\\scriptsize"
            elseif d.max_line_length < 70
                font_size = "\\fontsize{8}{10}"
            else
                font_size = "\\tiny"

        return {
                text: result
                gobble: d.gobble
                max_line_length: d.max_line_length
                font_size: font_size
            }

    process_file: (file) ->
        file_lines = {}

        for line in io.lines file do
            table.insert file_lines, line

        result = d.process_input file_lines
        return result
}

