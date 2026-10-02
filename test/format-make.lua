local repo = assert(vim.env.EPITECH_DUMP_ARCH_REPO)
local plugin = repo .. "/nvim/epitech.nvim"
vim.opt.runtimepath:prepend(plugin)
package.path = plugin .. "/lua/?.lua;" .. plugin .. "/lua/?/init.lua;" .. package.path
local specs = dofile(repo .. "/nvim/lazyvim-spec.lua")
local conform_opts = {}
specs[3].opts(nil, conform_opts)
assert(vim.deep_equal(conform_opts.formatters_by_ft.make, { "bake" }))

local input = table.concat({
  "##",
  "## EPITECH PROJECT, 2026",
  "## Day10",
  "## File description:",
  "## Makefile",
  "##",
  "",
  "NAME=demo",
  "",
  "all: $(NAME)",
  "\t@echo  done",
  "",
}, "\n")
local result = vim.system({ "mbake", "format", "--stdin" }, { stdin = input, text = true }):wait()
assert(result.code == 0, result.stderr)
assert(result.stdout:find("## EPITECH PROJECT, 2026", 1, true), "Epitech Makefile header changed")
assert(result.stdout:find("NAME = demo", 1, true), "Makefile assignment was not formatted")
assert(result.stdout:find("\n\t@echo  done", 1, true), "recipe tab or shell command changed")
assert(not result.stdout:find("/*", 1, true), "C syntax leaked into Makefile")

local second = vim.system({ "mbake", "format", "--stdin" }, { stdin = result.stdout, text = true }):wait()
assert(second.code == 0 and second.stdout == result.stdout, "Makefile formatter is not idempotent")
print("Epitech Makefile formatter tests passed")
