local repo = assert(vim.env.EPITECH_DUMP_ARCH_REPO, "EPITECH_DUMP_ARCH_REPO is required")
local plugin = repo .. "/nvim/epitech.nvim"
vim.opt.runtimepath:prepend(plugin)
vim.opt.runtimepath:append(plugin .. "/after")
package.path = plugin .. "/lua/?.lua;" .. plugin .. "/lua/?/init.lua;" .. package.path

local epitech = require("epitech")

local function assert_equal(actual, expected, label)
  if not vim.deep_equal(actual, expected) then
    error(("%s\nexpected: %s\nactual:   %s"):format(label, vim.inspect(expected), vim.inspect(actual)))
  end
end

local expected_header = {
  "/*",
  "** EPITECH PROJECT, " .. os.date("%Y"),
  "** Day 08",
  "** File description:",
  "** Copy string in allocated memory",
  "*/",
}

local specs = dofile(repo .. "/nvim/lazyvim-spec.lua")
assert_equal(specs[1].import, "lazyvim.plugins.extras.lang.clangd", "clangd extra")
specs[2].init()
specs[2].config()
assert_equal(vim.filetype.match({ filename = "example.h" }), "c", "header filetype")
assert(vim.api.nvim_get_commands({ builtin = false }).EpitechHeader, "EpitechHeader command")
local conform_opts = {}
specs[3].opts(nil, conform_opts)
assert_equal(conform_opts.formatters_by_ft.c, { "epitech_vim" }, "Conform C formatter")
assert(conform_opts.formatters.epitech_vim, "custom formatter config")

local answers = { "Day 08", "Copy string in allocated memory" }
vim.ui.input = function(_, callback)
  callback(table.remove(answers, 1))
end
epitech.insert_header()
assert_equal(vim.api.nvim_buf_get_lines(0, 0, 6, false), expected_header, "header insertion")

local before = vim.api.nvim_buf_line_count(0)
local notice
vim.notify = function(message)
  notice = message
end
epitech.insert_header()
assert_equal(vim.api.nvim_buf_line_count(0), before, "duplicate header line count")
assert_equal(notice, "This file already has an Epitech header", "duplicate header notice")

local vim_config = vim.fn.tempname()
vim.fn.writefile({
  "set tabstop=4",
  "set shiftwidth=4",
  "set expandtab",
  "set autoindent",
  "set smartindent",
  "set fileformat=unix",
}, vim_config)

local formatter = epitech.formatter({ vim_config = vim_config })
assert(formatter.condition(), "formatter should be available")
local input = table.concat({
  "/*",
  " ** EPITECH PROJECT, 2026",
  " ** Day 08",
  " ** File description:",
  " ** Copy string in allocated memory",
  " */",
  "",
  "int main(void){",
  "return 0;",
  "}",
  "",
}, "\n")
local command = vim.list_extend({ formatter.command }, formatter.args)
local result = vim.system(command, { stdin = input, text = true }):wait()
vim.uv.fs_unlink(vim_config)
assert_equal(result.code, 0, "formatter exit code")
assert_equal(result.stderr, "", "formatter stderr")
assert_equal(result.stdout, table.concat({
  "/*",
  "** EPITECH PROJECT, 2026",
  "** Day 08",
  "** File description:",
  "** Copy string in allocated memory",
  "*/",
  "",
  "int main(void){",
  "    return 0;",
  "}",
  "",
}, "\n"), "formatter output")

vim.cmd("filetype plugin on")
vim.bo.filetype = "c"
assert_equal(vim.bo.tabstop, 4, "C tabstop")
assert_equal(vim.bo.shiftwidth, 4, "C shiftwidth")
assert_equal(vim.bo.expandtab, true, "C expandtab")
assert_equal(vim.bo.comments, "s:/*,m:**,ex:*/", "C comments")

vim.api.nvim_create_user_command("EpitechHeader", "echo 'custom'", {
  desc = "Custom header command",
  force = true,
})
vim.keymap.set("n", "<leader>cH", function() end, { desc = "Custom header mapping" })
epitech.setup()
assert_equal(
  vim.api.nvim_get_commands({ builtin = false }).EpitechHeader.definition,
  "echo 'custom'",
  "existing header command"
)
local custom_mapping = vim.fn.maparg("<leader>cH", "n", false, true)
assert_equal(custom_mapping.desc, "Custom header mapping", "existing header mapping")

print("Epitech Neovim tests passed")
