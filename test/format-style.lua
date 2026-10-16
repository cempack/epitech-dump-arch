local repo = assert(vim.env.EPITECH_DUMP_ARCH_REPO)
local plugin = repo .. "/nvim/epitech.nvim"
vim.opt.runtimepath:prepend(plugin)
package.path = plugin .. "/lua/?.lua;" .. plugin .. "/lua/?/init.lua;" .. package.path

local epitech = require("epitech")
local tempdir = vim.fn.tempname()
vim.fn.mkdir(tempdir, "p")

local ok, err = pcall(function()
  local filename = tempdir .. "/arithmetic.c"
  local input = table.concat({
    "/*",
    "** EPITECH PROJECT, " .. os.date("%Y"),
    "** Formatter test",
    "** File description:",
    "** Arithmetic helpers",
    "*/",
    "",
    "int add(int a,int b){return a+b;}",
    "int sub(int a,int b){return a-b;}",
    "",
  }, "\n")
  local formatter = epitech.formatter()
  assert(formatter.condition(), "Epitech formatter prerequisites missing")
  local command = vim.list_extend({ formatter.command }, formatter.args)
  local formatted = vim.system(command, { stdin = input, text = true }):wait()
  assert(formatted.code == 0, formatted.stderr)
  assert(formatted.stdout:find("int add%(int a, int b%)\n{\n    return a %+ b;\n}\n\nint sub"), formatted.stdout)
  local twice = vim.system(command, { stdin = formatted.stdout, text = true }):wait()
  assert(twice.stdout == formatted.stdout, "formatter is not idempotent")
  vim.fn.writefile(vim.split(formatted.stdout:gsub("\n$", ""), "\n", { plain = true }), filename)
  local checked = vim.system({ "epiclang", "-x", "c", "-fsyntax-only", filename }, { text = true }):wait()
  assert(checked.code == 0, checked.stderr)
  assert(checked.stderr == "", checked.stderr)

  local directive_input = table.concat({
    "#if defined(THIS_IS_A_VERY_LONG_CONDITION) || defined(THIS_IS_ANOTHER_VERY_LONG_CONDITION)",
    "#define LONG_MACRO(value) (((value) + 1234567890123456789012345678901234567890) * 2)",
    "#endif",
    "",
  }, "\n")
  local directives = vim.system(command, { stdin = directive_input, text = true }):wait()
  assert(directives.code == 0, directives.stderr)
  assert(not directives.stdout:find("\\\n", 1, true), "formatter introduced a forbidden continuation")
  assert(directives.stdout:find("    #define LONG_MACRO", 1, true), directives.stdout)

  local long_input = table.concat({
    "/*",
    "** EPITECH PROJECT, " .. os.date("%Y"),
    "** Formatter test",
    "** File description:",
    "** Arithmetic helpers",
    "*/",
    "",
    "int sum_four_long_named_values(int first_long_value,int second_long_value,int third_long_value,int fourth_long_value){return first_long_value+second_long_value+third_long_value+fourth_long_value;}",
    "",
  }, "\n")
  local long_formatted = vim.system(command, { stdin = long_input, text = true }):wait()
  assert(long_formatted.code == 0, long_formatted.stderr)
  for _, line in ipairs(vim.split(long_formatted.stdout, "\n", { plain = true })) do
    assert(vim.fn.strdisplaywidth(line) < 80, "line exceeds C-F3: " .. line)
  end
  vim.fn.writefile(vim.split(long_formatted.stdout:gsub("\n$", ""), "\n", { plain = true }), filename)
  local long_checked = vim.system({ "epiclang", "-x", "c", "-fsyntax-only", filename }, { text = true }):wait()
  assert(long_checked.code == 0, long_checked.stderr)
  assert(long_checked.stderr == "", long_checked.stderr)

  local control_input = table.concat({
    "/*",
    "** EPITECH PROJECT, " .. os.date("%Y"),
    "** Formatter test",
    "** File description:",
    "** Arithmetic helpers",
    "*/",
    "",
    "int clamp(int value,int low,int high){if(value<low){return low;}if(value>high){return high;}return value;}",
    "",
  }, "\n")
  local control_formatted = vim.system(command, { stdin = control_input, text = true }):wait()
  assert(control_formatted.code == 0, control_formatted.stderr)
  assert(control_formatted.stdout:find("if %(value < low%) {\n        return low;\n    }"), control_formatted.stdout)
  vim.fn.writefile(vim.split(control_formatted.stdout:gsub("\n$", ""), "\n", { plain = true }), filename)
  local control_checked = vim.system({ "epiclang", "-x", "c", "-fsyntax-only", filename }, { text = true }):wait()
  assert(control_checked.code == 0, control_checked.stderr)
  assert(control_checked.stderr == "", control_checked.stderr)

  local switch_input = table.concat({
    "/*",
    "** EPITECH PROJECT, " .. os.date("%Y"),
    "** Formatter test",
    "** File description:",
    "** Arithmetic helpers",
    "*/",
    "",
    "int classify(int value){switch(value){case 0:return 1;case 1:{value++;return value;}default:break;}return 0;}",
    "",
  }, "\n")
  local switch_formatted = vim.system(command, { stdin = switch_input, text = true }):wait()
  assert(switch_formatted.code == 0, switch_formatted.stderr)
  assert(switch_formatted.stdout:find(table.concat({
    "    switch %(value%) {",
    "        case 0:",
    "            return 1;",
    "        case 1:",
    "            {",
    "                value%+%+;",
    "                return value;",
    "            }",
    "        default:",
    "            break;",
    "    }",
  }, "\n")), switch_formatted.stdout)
  local switch_twice = vim.system(command, { stdin = switch_formatted.stdout, text = true }):wait()
  assert(switch_twice.stdout == switch_formatted.stdout, "switch formatting is not idempotent")
  vim.fn.writefile(vim.split(switch_formatted.stdout:gsub("\n$", ""), "\n", { plain = true }), filename)
  local switch_checked = vim.system({ "epiclang", "-x", "c", "-fsyntax-only", filename }, { text = true }):wait()
  assert(switch_checked.code == 0, switch_checked.stderr)
  assert(switch_checked.stderr == "", switch_checked.stderr)
end)

vim.fn.delete(tempdir, "rf")
assert(ok, err)
print("Epitech C layout passes Banana")
