#! /usr/bin/env lua
--
-- diverb.lua
-- Copyright (C) 2017 Ivan Čukić <ivan.cukic(at)kde.org>
--
-- Distributed under terms of the MIT license.
--

local end_verb = '%s*\\end{diverb}'
diverb_buffer = {}
diverb_buffer[0] = "Test"

function diverb_read_buffer(buffer)
    if buffer:match(end_verb) then
        return buffer
    end
    table.insert(diverb_buffer, buffer)
    -- tex.print("\\begin{verbatim}" .. diverb_buffer .. "\\end{verbatim}")
    return ""
end

function start_recording()
    diverb_buffer = {}

    luatexbase.add_to_callback(
        'process_input_buffer',
        diverb_read_buffer,
        'diverb_read_buffer')
end

function stop_recording()
    luatexbase.remove_from_callback(
        'process_input_buffer',
        'diverb_read_buffer')

    markup_bold_pattern = "^//[ ^]*$"
    gobble_match = "^// *|$"

    -- tex.print("\\begin{verbatim}\r\n")

    line_co = table.count(diverb_buffer)

    output = ""
    gobble = 0
    unimportant = false

    for i = 1, line_co do
        current_line = diverb_buffer[i]
        current_line = current_line:gsub(":::", "▮codeUnimportant◀⋯▶")

        current_line = current_line:gsub(
                "// <([0-9])>$",
                "▮circled◀%1▶"
            )

        -- is this the gobble definition?
        if i == 1 and current_line:match(gobble_match) then
            gobble = current_line:find("|")

        elseif current_line:match("^//") then
            if current_line:match(markup_bold_pattern) then
                -- nothing

            elseif current_line == "//~" then
                unimportant = true

            elseif current_line == "//!" then
                unimportant = false

            end

        else
            if unimportant then
                -- This needs to be grayed-out
                output = output .. current_line .. "\r\n"
                -- output = output .. "▮codeUnimportant◀ Hello " .. current_line .. "▶" .. "\r\n"
                -- print(output)

            elseif i == line_co then
                -- The last line
                output = output .. current_line .. "\r\n"

            else
                -- Not the last line
                current_markup = diverb_buffer[i + 1]

                if current_markup:match(markup_bold_pattern) then
                    -- We have the markup

                    is_bold = false

                    for ci = 1, #current_line do
                        c = current_line:sub(ci, ci)
                        m = current_markup:sub(ci, ci)

                        if not is_bold and m == "^" then
                            -- we are using Palochka for command start
                            output = output .. "▮codeHighlight◀" -- going bold
                            is_bold = true

                        elseif is_bold and not (m == "^") then
                            output = output .. "▶" -- not bold anymore
                            is_bold = false

                        end

                        output = output .. c

                    end

                    if is_bold then
                        output = output .. "▶" -- not bold anymore
                    end

                    output = output .. "\r\n"

                else
                    -- We do not have the markup
                    output = output .. current_line .. "\r\n"

                end
            end
        end
    end

    tex.print(
            "\\begin{Verbatim}"
            .. "[ commandchars=▮◀▶ "
            .. string.format(", gobble=%d ", gobble)
            .. ", mathescape=true "
            .. "]\r\n"
            .. output
            .. "\\end{Verbatim}\r\n"
        )
end

