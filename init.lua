local opt = vim.opt
local map = vim.keymap.set

vim.g.mapleader = " "
vim.cmd("filetype plugin indent on")
vim.cmd("syntax enable")

-- отступы
opt.tabstop = 4
opt.shiftwidth = 4
opt.expandtab = true
opt.smartindent = true
opt.autoindent = true
opt.shiftround = true

--
opt.encoding = "utf-8"
opt.fileencoding = "utf-8"
opt.fileencodings = { "utf-8", "ucs-bom", "cp1251", "koi8-r", "latin1" }
opt.autoread = true
opt.hidden = true
opt.confirm = true
opt.undofile = true
opt.undolevels = 10000
opt.swapfile = false
opt.backup = false
opt.writebackup = false
opt.clipboard = "unnamedplus"
opt.mouse = "a"

-- поиск
opt.ignorecase = true
opt.smartcase = true
opt.incsearch = true
opt.hlsearch = true
opt.wrapscan = true
opt.inccommand = "split"

-- редактор
opt.guicursor = "a:block"
opt.number = true
opt.relativenumber = true
opt.signcolumn = "yes"
opt.termguicolors = true
opt.background = "dark"
opt.scrolloff = 6
opt.sidescrolloff = 6
opt.wrap = false
opt.splitbelow = true
opt.splitright = true
opt.showmode = false
opt.laststatus = 3
opt.completeopt = { "menu", "menuone", "noselect" }
opt.updatetime = 200
opt.winborder = "rounded"
vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], { desc = "Выйти в n в терминале" })

map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Убрать подсветку поиска" })

vim.pack.add({
    "https://github.com/folke/which-key.nvim",
    "https://github.com/nvim-tree/nvim-tree.lua",
    "https://github.com/nvim-lua/plenary.nvim",
    "https://github.com/nvim-telescope/telescope.nvim",
    "https://github.com/nvim-lualine/lualine.nvim",
    "https://github.com/lukas-reineke/indent-blankline.nvim",
    "https://github.com/mason-org/mason.nvim",
    "https://github.com/mason-org/mason-lspconfig.nvim",
    "https://github.com/neovim/nvim-lspconfig",
    "https://github.com/saghen/blink.lib",
    "https://github.com/saghen/blink.cmp",
}, { confirm = false, load = true })

vim.cmd.colorscheme("bark")

require("ibl").setup({
    indent = { char = "│" },
    scope = { enabled = false },
})

require("lualine").setup({
    options = {
        theme = "auto",
        icons_enabled = false,
        globalstatus = true,
        component_separators = "",
        section_separators = "",
    },
    sections = {
        lualine_a = {
            { "mode", fmt = function(mode) return mode:sub(1, 1) end },
        },
        lualine_b = { "branch" },
        lualine_c = {
            { "filename", path = 1, symbols = { modified = " +", readonly = " -", unnamed = "[No Name]" } },
        },
        lualine_x = {
            { "diagnostics", symbols = { error = "E ", warn = "W ", info = "I ", hint = "H " } },
            { "lsp_status",  icon = "",                                                        show_name = true },
        },
        lualine_y = { "progress" },
        lualine_z = { "location" },
    },
    inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = { "filename" },
        lualine_x = { "location" },
        lualine_y = {},
        lualine_z = {},
    },
    extensions = { "nvim-tree", "quickfix" },
})

require("telescope").setup({
    defaults = {
        layout_strategy = "horizontal",
        layout_config = { prompt_position = "top" },
        sorting_strategy = "ascending",
    },
    pickers = {
        find_files = { hidden = true },
    },
})

local telescope = require("telescope.builtin")
map("n", "<leader>ff", telescope.find_files, { desc = "Найти файл" })
map("n", "<leader>fg", telescope.live_grep, { desc = "Поиск по тексту" })
map("n", "<leader>fb", telescope.buffers, { desc = "Открытые буферы" })

local cmp = require("blink.cmp")
cmp.setup({
    keymap = { preset = "default" },
    completion = {
        documentation = { auto_show = true, auto_show_delay_ms = 300 },
        ghost_text = { enabled = true },
    },
    signature = { enabled = true },
    sources = { default = { "lsp", "path", "snippets", "buffer" } },
    fuzzy = { implementation = "lua" },
})

vim.diagnostic.config({
    severity_sort = true,
    update_in_insert = false,
    underline = true,
    virtual_text = { spacing = 2, source = "if_many", prefix = "●" },
    float = { source = "if_many", border = "rounded" },
    signs = {
        text = {
            [vim.diagnostic.severity.ERROR] = "E",
            [vim.diagnostic.severity.WARN] = "W",
            [vim.diagnostic.severity.INFO] = "I",
            [vim.diagnostic.severity.HINT] = "H",
        },
    },
})

local capabilities = cmp.get_lsp_capabilities()

vim.lsp.config("lua_ls", {
    capabilities = capabilities,
    settings = {
        Lua = {
            runtime = { version = "LuaJIT" },
            completion = { callSnippet = "Replace" },
            diagnostics = { globals = { "vim" } },
            workspace = {
                checkThirdParty = false,
                library = { vim.env.VIMRUNTIME },
            },
            telemetry = { enable = false },
            hint = { enable = true },
        },
    },
})

vim.lsp.config("clangd", {
    capabilities = capabilities,
    cmd = {
        "clangd",
        "--background-index",
        "--clang-tidy",
        "--completion-style=detailed",
        "--header-insertion=iwyu",
        "--function-arg-placeholders=true",
        "--fallback-style=WebKit",
    },
})

require("mason").setup({
    ui = { border = "rounded" },
})
require("mason-lspconfig").setup({
    ensure_installed = { "lua_ls", "clangd" },
    automatic_enable = { "lua_ls", "clangd" },
})

vim.api.nvim_create_autocmd("LspAttach", {
    desc = "Удобные клавиши LSP",
    callback = function(event)
        local function lsp_map(mode, lhs, rhs, desc)
            map(mode, lhs, rhs, { buffer = event.buf, desc = "LSP: " .. desc })
        end

        lsp_map("n", "gd", telescope.lsp_definitions, "к определению")
        lsp_map("n", "<leader>ls", telescope.lsp_dynamic_workspace_symbols, "символы проекта")
        lsp_map("n", "<leader>lf", function()
            vim.lsp.buf.format({ async = true })
        end, "форматировать")

        local client = vim.lsp.get_client_by_id(event.data.client_id)
        if client and client:supports_method("textDocument/inlayHint") then
            vim.lsp.inlay_hint.enable(false, { bufnr = event.buf })
            lsp_map("n", "<leader>lh", function()
                local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf })
                vim.lsp.inlay_hint.enable(not enabled, { bufnr = event.buf })
            end, "подсказки типов")
        end
    end,
})

require("which-key").setup({
    preset = "helix",
    delay = 250,
    icons = { mappings = false },
})

vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

require("nvim-tree").setup({
    view = { width = 32 },
    renderer = {
        group_empty = true,
        indent_markers = { enable = true },
    },
    update_focused_file = { enable = true },
    filters = {
        dotfiles = false,
        git_clean = false,
        no_buffer = false,
        custom = {},
        exclude = {},
    },
    git = {
        enable = true,
        ignore = false,
        show_on_dirs = true,
        show_on_open_dirs = true,
        timeout = 400,
    },
})
map("n", "<leader>e", "<cmd>NvimTreeToggle<CR>", { desc = "Файловое дерево" })
