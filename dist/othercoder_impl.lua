local config = {
  buffer = { },
  prefix = "//>",
  comment = "//",
  latex_start_char = "▮",
  latex_open_char = "◀",
  latex_close_char = "▶",
  bold_marker = "^",
  normal_marker = "normal",
  important_marker = "important",
  unimportant_marker = "fade"
}
utils = {
  trim = function(s)
    return s:gsub("^%s*(.-)%s*$", "%1")
  end,
  for_each = function(items, fun)
    for item in items do
      fn(item)
    end
  end,
  consecutive_pairs = function(items, last)
    local result = { }
    local items_count = #items
    for index = 1, items_count do
      table.insert(result, {
        first = items[index],
        second = (function()
          if index + 1 >= items_count then
            return last
          else
            return items[index + 1]
          end
        end)()
      })
    end
    return result
  end
}
d = {
  normal_state = 0,
  important_state = 1,
  unimportant_state = 2,
  auto_font_size = false,
  state = normal_state,
  gobble = 0,
  max_line_length = 0,
  enable_debug = false,
  enable_debug_full = false,
  bold_pattern = "^" .. config.prefix .. "[ " .. config.bold_marker .. "]*$",
  latex = function(command, body)
    return config.latex_start_char .. command .. config.latex_open_char .. body .. config.latex_close_char
  end,
  debug = function(message)
    if d.enable_debug then
      return texio.write_nl("othercoder: " .. message)
    end
  end,
  process_first_line = function(current_line)
    d.gobble = current_line:find("|")
    if d.gobble == nil then
      d.gobble = 0
    else
      d.gobble = d.gobble - 1
    end
    d.debug("Detected gobble while processing the first line: " .. d.gobble)
    d.debug(" -> " .. current_line)
    return ""
  end,
  process_markup_line = function(current_line)
    if current_line:match(config.normal_marker) then
      d.state = d.normal_state
    elseif current_line:match(config.important_marker) then
      d.state = d.important_state
    elseif current_line:match(config.unimportant_marker) then
      d.state = d.unimportant_state
    end
    return ""
  end,
  process_normal_line = function(current_line, next_line)
    if d.max_line_length < string.len(current_line) then
      d.max_line_length = string.len(current_line)
    end
    local current_line_state = d.state
    local current_line_markup_text = ""
    current_line = current_line:gsub(config.prefix .. "(.*)", function(s)
      current_line_markup_text = utils.trim(s)
    end)
    if current_line_markup_text:match(config.normal_marker) then
      current_line_state = d.normal_state
    elseif current_line_markup_text:match(config.important_marker) then
      current_line_state = d.important_state
    elseif current_line_markup_text:match(config.unimportant_marker) then
      current_line_state = d.unimportant_state
    end
    current_line = current_line:gsub(":::", d.latex("othercoderUnimportant", "⋯"))
    current_line = current_line:gsub("// <([0-9])>", d.latex("othercoderCircled", "%1"))
    local current_comment_text = ""
    current_line = current_line:gsub("// |(.*)", function(s)
      current_comment_text = utils.trim(s)
    end)
    current_comment_text = current_comment_text:gsub("`([^`]*)`", d.latex("texttt", "%1"))
    current_comment_text = current_comment_text:gsub("<([0-9])>", d.latex("othercoderCircled", "%1"))
    current_line = current_line:gsub("// |(.*)", d.latex("othercoderBarred", "") .. " " .. d.latex("sffamily", " " .. current_comment_text))
    local output = ""
    if d.state == d.unimportant_state then
      current_line = current_line:gsub("(%s*)(.*)", "%1" .. d.latex("othercoderUnimportant", "%2"))
      output = output .. current_line
    elseif d.state == d.important_state then
      current_line = current_line:gsub("(%s*)(.*)", "%1" .. d.latex("othercoderImportant", "%2"))
      output = output .. current_line
    else
      if next_line:match(d.bold_pattern) then
        local is_bold = false
        for ci = 1, #current_line do
          local c = current_line:sub(ci, ci)
          local m = next_line:sub(ci, ci)
          if not is_bold and m == "^" then
            output = output .. (config.latex_start_char .. "othercoderImportant" .. config.latex_open_char)
            is_bold = true
          elseif is_bold and not (m == "^") then
            output = output .. config.latex_close_char
            is_bold = false
          end
          output = output .. c
        end
        if is_bold then
          output = output .. consig.latex_close_char
        end
      else
        output = output .. current_line
      end
    end
    output = output .. "\r\n"
    return output
  end,
  process_line = function(current_line, next_line)
    if current_line:match("^" .. config.prefix) then
      return d.process_markup_line(current_line)
    else
      return d.process_normal_line(current_line, next_line)
    end
  end,
  process_input = function(lines)
    d.state = d.normal_state
    d.gobble = 0
    d.max_line_length = 0
    local result = ""
    for index, pair in ipairs(utils.consecutive_pairs(lines, "")) do
      local current_line = pair.first
      local next_line = pair.second
      if index == 1 and current_line:match("^" .. config.prefix) then
        result = result .. d.process_first_line(current_line)
      else
        result = result .. d.process_line(pair.first, pair.second)
      end
    end
    local font_size = ""
    if d.auto_font_size then
      d.max_line_length = d.max_line_length - d.gobble
      if d.max_line_length < 40 then
        font_size = "\\large"
      elseif d.max_line_length < 45 then
        font_size = "\\normalsize"
      elseif d.max_line_length < 55 then
        font_size = "\\footnotesize"
      elseif d.max_line_length < 60 then
        font_size = "\\scriptsize"
      elseif d.max_line_length < 70 then
        font_size = "\\fontsize{8}{10}"
      else
        font_size = "\\tiny"
      end
    end
    return {
      text = result,
      gobble = d.gobble,
      max_line_length = d.max_line_length,
      font_size = font_size
    }
  end,
  process_file = function(file)
    local file_lines = { }
    for line in io.lines(file) do
      table.insert(file_lines, line)
    end
    local result = d.process_input(file_lines)
    return result
  end
}
