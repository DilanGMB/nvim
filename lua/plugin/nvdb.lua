local setmap = vim.api.nvim_set_keymap
local options = { expr = false, silent = false, noremap = true }
local nvim_db = require("nvimdb")

nvim_db.set_view_options {
  view_name = "Custom",
  winopt = {}
}
nvim_db.add_filetypes {
  "java"
}

setmap("v", "<Leader>rs", ":RunQuerySel<CR>", options)
setmap("n", "<Leader>mm", ":RunQueryLn<CR>", options)
setmap("n", "<C-l>",      ":ToggleViewer<CR>", options)
