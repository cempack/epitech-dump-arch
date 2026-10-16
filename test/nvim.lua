local repo = assert(vim.env.EPITECH_DUMP_ARCH_REPO, "EPITECH_DUMP_ARCH_REPO is required")
local plugin = assert(vim.env.EPITECH_NVIM_DIR, "EPITECH_NVIM_DIR is required")
vim.opt.runtimepath:prepend(plugin)
vim.opt.runtimepath:append(plugin .. "/after")
package.path = plugin .. "/lua/?.lua;" .. plugin .. "/lua/?/init.lua;" .. package.path

local function assert_equal(actual, expected, label)
  if not vim.deep_equal(actual, expected) then
    error(("%s\nexpected: %s\nactual:   %s"):format(label, vim.inspect(expected), vim.inspect(actual)))
  end
end

local specs = dofile(repo .. "/nvim/lazyvim-spec.lua")
assert_equal(specs[1].import, "lazyvim.plugins.extras.lang.clangd", "clangd extra")
assert_equal(specs[2][1], "cempack/epitech.nvim", "plugin source")
assert_equal(specs[2].dir, nil, "plugin is not loaded from a local copy")
specs[2].init()
specs[2].config()
assert_equal(vim.filetype.match({ filename = "example.h" }), "c", "header filetype")
assert(vim.api.nvim_get_commands({ builtin = false }).EpitechHeader, "EpitechHeader command")
assert(vim.api.nvim_get_commands({ builtin = false }).EpitechGuard, "EpitechGuard command")
assert_equal(specs[3].dependencies, { "epitech.nvim" }, "Conform depends on the plugin's lazy.nvim name")
local conform_opts = {}
specs[3].opts(nil, conform_opts)
assert_equal(conform_opts.formatters_by_ft.c, { "epitech_vim" }, "Conform C formatter")
assert_equal(conform_opts.formatters_by_ft.make, { "bake" }, "Conform Makefile formatter")
assert(conform_opts.formatters.epitech_vim, "custom formatter config")

print("Epitech LazyVim spec tests passed")
