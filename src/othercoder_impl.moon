--
-- othercoder.moon
-- Copyright (C) 2017 Ivan Čukić <ivan.cukic(at)kde.org>
--
-- License: GNU Lesser General Public License 3
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

    state: normal_state
    gobble: 0

    bold_pattern: "^" .. config.prefix .. "[ " .. config.bold_marker .. "]*$"

    latex: (command, body) ->
        return config.latex_start_char .. command .. config.latex_open_char .. body .. config.latex_close_char

    process_first_line: (current_line) ->
        -- Do we have gobble bar?
        d.gobble = current_line\find "|"
        if d.gobble == nil then d.gobble = 0

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
        -- Checking for in-line markup
        current_line_state = d.state
        current_line_markup_text = ""
        current_line = current_line\gsub config.prefix .. "(.*)",
                                         (s) -> current_line_markup_text = utlis.trim s


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

        output ..= "\r\n"
        return output






    process_line: (current_line, next_line) ->
        if current_line\match("^" .. config.prefix)
            return d.process_markup_line current_line

        else
            return d.process_normal_line(current_line, next_line)


    process_input: (lines) ->
        result = ""
        for index, pair in ipairs utils.consecutive_pairs lines, ""
            current_line = pair.first
            next_line    = pair.second

            if index == 1 and current_line\match "^" .. config.prefix then
                result ..= d.process_first_line current_line
            else
                result ..= d.process_line pair.first, pair.second

        return result

    process_file: (file) ->
        file_lines = {}

        for line in io.lines file do
            table.insert file_lines, line

        result = d.process_input file_lines
        moon.p result
        return result
}

