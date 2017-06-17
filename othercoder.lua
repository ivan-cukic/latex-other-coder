#! /usr/bin/env lua
--
-- othercoder.lua
-- Copyright (C) 2017 Ivan Čukić <ivan.cukic(at)kde.org>
--
-- Distributed under terms of the MIT license.
--

local end_verb = '%s*\\end{othercoder}'
othercoder_buffer = {}

function othercoder_read_buffer(buffer)
    if buffer:match(end_verb) then
        return buffer
    end
    table.insert(othercoder_buffer, buffer)
    return ""
end

function othercoder_start_recording()
    othercoder_buffer = {}

    luatexbase.add_to_callback('process_input_buffer',
                               othercoder_read_buffer,
                               'othercoder_read_buffer')
end

function othercoder_stop_recording()
    luatexbase.remove_from_callback('process_input_buffer',
                                    'othercoder_read_buffer')

    require "dist/othercoder_impl.lua"

    tex.print(
            "\\begin{Verbatim}"
            .. "[ commandchars=▮◀▶ "
            .. string.format(", gobble=%d ", d.gobble)
            .. ", codes={\\catcode`$=3} "
            .. "]\r\n"
            .. d.process_input(othercoder_buffer)
            .. "\\end{Verbatim}\r\n"
        )
end

