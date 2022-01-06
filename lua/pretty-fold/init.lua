local ffi = require("ffi")
ffi.cdef'int curwin_col_off(void);'
local wo = vim.wo
local fn = vim.fn
local api = vim.api

local M = {
   ---Table with all 'foldtext' functions.
   foldtext = {}
}

-- Labels for every vim foldmethod config table (:help foldmethod) and one
-- general config unlabeled table (accessible with config[1]) to seek into if
-- no value was found in foldmethod specific config table.
local foldmethods = { 1, 'manual', 'indent', 'expr', 'marker', 'syntax' }

local default_config = {
   fill_char = '•',
   remove_fold_markers = true,

   -- Keep the indentation of the content of the fold string.
   keep_indentation = true,

   -- Possible values:
   -- "delete" : Delete all comment signs from the fold string.
   -- "spaces" : Replace all comment signs with equal number of spaces.
   --  false   : Do nothing with comment signs.
   ---@type string|boolean
   comment_signs = 'spaces',

   -- List of patterns that will be removed from content foldtext section.
   stop_words = {
      '@brief%s*', -- (for cpp) Remove '@brief' and all spaces after.
   },

   sections = {
      left = {
         'content',
      },
      right = {
         ' ', 'number_of_folded_lines', ': ', 'percentage', ' ',
         function(config) return config.fill_char:rep(3) end
      }
   },

   add_close_pattern = true,
   matchup_patterns = {
      { '{', '}' },
      { '%(', ')' }, -- % to escape lua pattern char
      { '%[', ']' }, -- % to escape lua pattern char
      { 'if%s', 'end' },
      { 'do%s', 'end' },
      { 'for%s', 'end' },
   },
}

-- The main function which produses the string which will be shown
-- in the fold line.
---@param config table
local function fold_text(config)
   config = config[wo.foldmethod]

   local r = { left = {}, right = {} }

   -- Get the text of all sections of the fold string.
   for _, lr in ipairs({'left', 'right'}) do
      for _, s in ipairs(config.sections[lr] or {}) do
         local sec = require('pretty-fold.sections')[s]
         table.insert(r[lr], vim.is_callable(sec) and sec(config) or sec)
      end
   end

   ---The width of offset of a window, occupied by line number column,
   ---fold column and sign column.
   ---@type number
   local gutter_width = ffi.C.curwin_col_off()

   local visible_win_width = api.nvim_win_get_width(0) - gutter_width

   -- The summation length of all sections of the fold text string.
   local fold_text_len = fn.strdisplaywidth( table.concat( vim.tbl_flatten( vim.tbl_values(r) )))

   r.expansion_str = string.rep(config.fill_char, visible_win_width - fold_text_len)

   return table.concat( vim.tbl_flatten({r.left, r.expansion_str, r.right}) )
end

local function configure_fold_text(input_config)
   local input_config_is_fdm_specific = false
   if input_config then
      for _, v in ipairs(foldmethods) do
         if input_config[v] then
            input_config_is_fdm_specific = true
            break
         end
      end
   end

   local config = {}
   for _, fdm in ipairs(foldmethods) do config[fdm] = {} end

   if input_config_is_fdm_specific then
      config = vim.tbl_deep_extend('force', config, input_config)
   elseif input_config then
      config[1] = vim.tbl_deep_extend('force', config[1], input_config)
   end

   for _, fdm in ipairs(foldmethods) do
      config[fdm] = setmetatable(config[fdm],
         { __index = (fdm == 1) and default_config or config[1] })
   end

   return config
end

-- Setup the global 'foldtext' vim option.
---@param config table
function M.setup(config)
   config = configure_fold_text(config)
   M.foldtext.global = function() return fold_text(config) end
   vim.opt.foldtext = 'v:lua.require("pretty-fold").foldtext.global()'
end

-- Setup the filetype specific window local 'foldtext' vim option.
---@param filetype string
---@param config table
function M.ft_setup(filetype, config)
   if not M.foldtext[filetype] then
      config = configure_fold_text(config)
      M.foldtext[filetype] = function() return fold_text(config) end
   end
   vim.opt_local.foldtext =
      string.format('v:lua.require("pretty-fold").foldtext.%s()', filetype)
end

return M
