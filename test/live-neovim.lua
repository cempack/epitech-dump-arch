-- Run with the installed LazyVim config: nvim --headless +"luafile test/live-neovim.lua" +qa!
local conform = require("conform")

local function has_formatter(name)
  for _, formatter in ipairs(conform.list_formatters(0)) do
    if formatter.name == name then
      return true
    end
  end
  return false
end

local buf = vim.api.nvim_create_buf(true, false)
vim.api.nvim_set_current_buf(buf)
vim.api.nvim_buf_set_name(buf, "/tmp/EpitechConformMakefile")
vim.bo[buf].filetype = "make"
vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
  "##", "## EPITECH PROJECT, 2026", "## Day10", "## File description:", "## Makefile", "##",
  "", "NAME=demo", "", "all: $(NAME)", "\t@echo  done",
})
assert(has_formatter("bake"), "Conform did not resolve bake for Makefiles")
conform.format({ bufnr = buf, async = false, lsp_format = "never" })
local result = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
assert(result[2] == "## EPITECH PROJECT, 2026", "Makefile header changed")
assert(vim.tbl_contains(result, "NAME = demo"), "Makefile was not formatted")
assert(vim.tbl_contains(result, "\t@echo  done"), "Makefile recipe was changed")

vim.api.nvim_buf_set_name(buf, "/tmp/epitech_conform.c")
vim.bo[buf].filetype = "c"
assert(has_formatter("epitech_vim"), "Conform did not resolve the Epitech C formatter")
vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
  "/*", "** EPITECH PROJECT, 2026", "** Day10", "** File description:", "** C file", "*/",
  "", "int main(void){return 0;}",
})
conform.format({ bufnr = buf, async = false, lsp_format = "never" })
result = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
assert(result[1] == "/*" and result[2] == "** EPITECH PROJECT, 2026" and result[6] == "*/",
  "Epitech C header changed")
assert(vim.tbl_contains(result, "    return 0;"), "Epitech C body was not formatted")
print("Live LazyVim/Conform C and Makefile resolution passed")
