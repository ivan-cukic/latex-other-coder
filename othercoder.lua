#! /usr/bin/env lua
--
-- othercoder.lua
-- Copyright (C) 2017 Ivan Čukić <ivan.cukic(at)kde.org>
--
-- Distributed under terms of the MIT license.
--

local end_verb = '%s*\\end{othercoder}'
othercoder_buffer = {}
othercoder_buffer[0] = "Test"

function othercoder_read_buffer(buffer)
    if buffer:match(end_verb) then
        return buffer
    end
    table.insert(othercoder_buffer, buffer)
    -- tex.print("\\begin{verbatim}" .. othercoder_buffer .. "\\end{verbatim}")
    return ""
end

function othercoder_start_recording()
    othercoder_buffer = {}

    luatexbase.add_to_callback(
        'process_input_buffer',
        othercoder_read_buffer,
        'othercoder_read_buffer')
end

function othercoder_stop_recording()
    luatexbase.remove_from_callback(
        'process_input_buffer',
        'othercoder_read_buffer')

    markup_bold_pattern = "^//[ ^]*$"

    gobble_match = "^// *|"
    unimportant_match = "^// *~"
    important_match = "^// *!"

    -- tex.print("\\begin{verbatim}\r\n")

    line_co = table.count(othercoder_buffer)

    output = ""
    gobble = 0
    unimportant = false

    for i = 1, line_co do
        current_line = othercoder_buffer[i]
        current_line = current_line:gsub(":::", "▮othercoderUnimportant◀⋯▶")

        current_line = current_line:gsub(
                "// <([0-9])>$",
                "▮othercoderCircled◀%1▶"
            )

        current_line = current_line:gsub(
                "// | <([0-9])>$",
                "▮othercoderBarred◀%1▶ ▮othercoderCircled◀%1▶"
            )

        current_line = current_line:gsub(
                "// |(.*)",
                "▮othercoderBarred◀▶ ▮sffamily◀%1▶"
            )

        -- is this the gobble definition?
        if i == 1 and current_line:match(gobble_match) then
            gobble = current_line:find("|")

        elseif current_line:match("^//.*") then
            if current_line:match(markup_bold_pattern) then
                -- nothing

            elseif current_line:match(unimportant_match) then
                unimportant = true

            elseif current_line:match(important_match) then
                unimportant = false

            end

        else
            if unimportant then
                -- This needs to be grayed-out
                -- output = output .. current_line .. "\r\n"
                current_line = current_line:gsub(
                        "(%s*)(.*)",
                        "%1▮othercoderUnimportant◀%2▶")
                output = output .. current_line .. "\r\n"
                -- print(output)

            elseif i == line_co then
                -- The last line
                output = output .. current_line .. "\r\n"

            else
                -- Not the last line
                current_markup = othercoder_buffer[i + 1]

                if current_markup:match(markup_bold_pattern) then
                    -- We have the markup

                    is_bold = false

                    for ci = 1, #current_line do
                        c = current_line:sub(ci, ci)
                        m = current_markup:sub(ci, ci)

                        if not is_bold and m == "^" then
                            -- we are using Palochka for command start
                            output = output .. "▮othercoderImportant◀" -- going bold
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

    -- print(
    --         "\\begin{Verbatim}"
    --         .. "[ commandchars=▮◀▶ "
    --         .. string.format(", gobble=%d ", gobble)
    --         -- .. ", mathescape=true "
    --         .. ", codes={\\catcode`$=3} "
    --         .. "]\r\n"
    --         .. output
    --         .. "\\end{Verbatim}\r\n"
    --     )

    tex.print(
            "\\begin{Verbatim}"
            .. "[ commandchars=▮◀▶ "
            .. string.format(", gobble=%d ", gobble)
            -- .. ", mathescape=true "
            .. ", codes={\\catcode`$=3} "
            .. "]\r\n"
            .. output
            .. "\\end{Verbatim}\r\n"
        )
end

