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


othercoder_buffer = {}



------------------------------------------------------------------------------
-- othercoder environment                                                   --
------------------------------------------------------------------------------

local othercoder_end_verb = '%s*\\end{othercoder}'


function othercoder_read_buffer(buffer)
    if buffer:match(othercoder_end_verb) then
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

    result = d.process_input(othercoder_buffer)

    d.debug("Detected gobble (result): " .. result.gobble .. " <-----")
    d.debug("Detected maximum line: " .. result.max_line_length .. " <-----")

    if d.enable_debug_full then
        texio.write_nl(
                "[[[\\begin{Verbatim}"
                .. "[ commandchars=▮◀▶ "
                .. string.format(", gobble=%d ", result.gobble)
                .. ", codes={\\catcode`$=3} "
                .. "]" .. "\r"
                .. result.text
                .. "\\end{Verbatim}\r]]]"
            )
    end

    tex.print(
            result.font_size
            .. "\\begin{Verbatim}"
            .. "[ commandchars=▮◀▶ "
            .. string.format(", gobble=%d ", result.gobble)
            .. ", codes={\\catcode`$=3} "
            .. "]" .. "\r"
            .. result.text
            .. "\\end{Verbatim}" .. "\r"
        )
end



------------------------------------------------------------------------------
-- othercoderboxed environment                                              --
------------------------------------------------------------------------------

local othercoderboxed_end_verb = '%s*\\end{othercoderboxed}'


function othercoderboxed_read_buffer(buffer)
    if buffer:match(othercoderboxed_end_verb) then
        return buffer
    end
    table.insert(othercoder_buffer, buffer)
    return ""
end


function othercoderboxed_start_recording()
    othercoder_buffer = {}

    luatexbase.add_to_callback('process_input_buffer',
                               othercoderboxed_read_buffer,
                               'othercoderboxed_read_buffer')
end


function othercoderboxed_stop_recording()
    luatexbase.remove_from_callback('process_input_buffer',
                                    'othercoderboxed_read_buffer')

    require "dist/othercoder_impl.lua"

    result = d.process_input(othercoder_buffer)

    d.debug("Detected gobble (result): " .. result.gobble .. " <-----")
    d.debug("Detected maximum line: " .. result.max_line_length .. " <-----")

    if d.enable_debug_full then
        texio.write_nl(
                "\\begin{tcolorbox}[size=tight,oversize,sharp corners,colback=othercoderBox,colframe=othercoderBox,left=56pt,right=90pt]"
                .. "[[[\\begin{Verbatim}"
                .. "[ commandchars=▮◀▶ "
                .. string.format(", gobble=%d ", result.gobble)
                .. ", codes={\\catcode`$=3} "
                .. "]" .. "\r"
                .. result.text
                .. "\\end{Verbatim}\r"
                .. "\\end{tcolorbox}\r]]]"
            )
    end

    tex.print(
            result.font_size
            .. "\\begin{tcolorbox}[size=tight,oversize,sharp corners,colback=othercoderBox,colframe=othercoderBox,left=56pt,right=90pt,top=0.3em,bottom=0.3em]"
            .. "\\begin{Verbatim}"
            .. "[ commandchars=▮◀▶ "
            .. string.format(", gobble=%d ", result.gobble)
            .. ", codes={\\catcode`$=3} "
            .. "]" .. "\r"
            .. result.text
            .. "\\end{Verbatim}\r"
            .. "\\end{tcolorbox}\r"
        )
end


------------------------------------------------------------------------------
-- package options                                                          --
------------------------------------------------------------------------------

function othercoder_enable_auto_font_size()
    require "dist/othercoder_impl.lua"
    d.auto_font_size = true
end


function othercoder_enable_debug()
    require "dist/othercoder_impl.lua"
    d.enable_debug = true
end


function othercoder_enable_debug_full()
    require "dist/othercoder_impl.lua"
    d.enable_debug = true
    d.enable_debug_full = true
end



