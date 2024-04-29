local CompletionSource = require("forester.completion")
local Commands = require("forester.commands")

local M = {}

local function add_treesitter_config()
  ---@class ParserInfo[]
  local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
  parser_config.forester = {
    install_info = {
      url = "https://github.com/kentookura/tree-sitter-forester",
      files = { "src/parser.c" },
      branch = "main",
      generate_requires_npm = false,
      requires_generate_from_grammar = false,
    },
    filetype = "tree",
  }
  vim.treesitter.language.register("forester", "forester")
end

local function setup(opts)
  ---@diagnostic disable-next-line: redefined-local
  local opts = opts or { tree_dirs = { "trees" } }

  vim.filetype.add({ extension = { tree = "forester" }, pattern = { ["*.tree"] = "forester" } })

  local cmp = require("cmp")

  cmp.register_source("forester", CompletionSource)
  cmp.setup({
    sources = { { name = "forester", dup = 0 } },
  })

  add_treesitter_config()
  for _, v in pairs(opts.tree_dirs) do
    vim.opt.path:append(v)
  end
  vim.opt.suffixesadd:prepend(".tree")

  vim.api.nvim_create_user_command("Forester", function(cmd)
    local prefix, _ = Commands.parse(cmd.args)
    Commands.cmd(prefix, opts)
  end, {
    bar = true,
    bang = true,
    nargs = "?",
    complete = function(_, line)
      local prefix, args = Commands.parse(line)
      if #args > 0 then
        return M.complete(prefix, args[#args])
      end
      return vim.tbl_filter(function(key)
        return key:find(prefix, 1, true) == 1
      end, vim.tbl_keys(Commands.commands))
    end,
  })

  if opts.conceal then
    vim.cmd(":set conceallevel=2")
  end

  vim.api.nvim_create_autocmd({ "BufNew", "BufEnter" }, {
    pattern = { "*.tree" },
    callback = function(args)
      vim.treesitter.start(args.buf, "forester")
    end,
  })
  -- local hover = require("hover")
  -- hover.setup({})
  -- hover.register(Preview.hover_provider)
end

M.setup = setup

return M
