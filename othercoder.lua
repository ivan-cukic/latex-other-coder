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

    -- print(
    --         "\\begin{Verbatim}"
    --         .. "[ commandchars=▮◀▶ "
    --         .. string.format(", gobble=%d ", d.gobble)
    --         .. ", codes={\\catcode`$=3} "
    --         .. "]\r\n"
    --         .. d.process_input(othercoder_buffer)
    --         .. "\\end{Verbatim}\r\n"
    --     )

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

