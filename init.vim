" Set default configurations {{{
let g:NvideConf_UseIdeFeature = 1
let g:NvideConf_UsePlugin = 1
let g:NvideConf_Lf_GtagsStoreInProject = 0
let g:NvideConf_Lf_Gtagslabel = "native-pygments"
let g:NvideConf_Lf_Gtagsconf = expand('~/gtags.conf')
let g:NvideConf_Lf_RootMarkers = ['.repo', '.root', '.svn', '.git']
let g:NvideConf_Lf_RgSearchType = ''
let g:NvideConf_CxxSemanticHighlight = 0
let g:Nvide_BuildCmd = "make"
let g:NvideConf_PythonVirtualEnv = ''
let g:NvideConf_UseDevIcons = 1
let g:NvideConf_PluginDirectory = join([stdpath("config"), "plugged/"], "/")
" default or set to some mirror like: 'https://github.com.cnpmjs.org/'
let g:NvideConf_PluginDownloadAddr = ''
" }}}

" Load user configurations {{{
function! LoadUserConf()
    let l:ConfFile = join([stdpath("config"), "nvide_user_conf.vim"], "/")
    if filereadable(l:ConfFile)
        execute("source " .. l:ConfFile)
    endif
endfunction
call LoadUserConf()
" }}}

" Load project-wide configurations {{{
function! LoadProjectConf()
    let l:ConfFile = join([getcwd(), ".vim", "project_conf.vim"], "/")
    if filereadable(l:ConfFile)
        execute("source " .. l:ConfFile)
    endif
endfunction
call LoadProjectConf()
" }}}

" Encodings {{{
set encoding=utf-8
set fileencodings=ucs-bom,utf-8,utf-16,gbk,big5,gb18030,cp936,latin-1
set fileformats=unix
" }}}

" Indent {{{
set tabstop=4
set shiftwidth=4
set expandtab
set smarttab
set cindent
set breakindent
set linebreak
set breakat=,;
" }}}

" Display {{{
set lcs=tab:>-,space:·,trail:!
set list
nnoremap <F3> :set list! list?<CR>

syntax on
set termguicolors

set cursorline
set laststatus=2
set scrolloff=6
set noshowmode             " no need to show mode when use airline/lightline
set showcmd                " Show already typed keys when more are expected.

set incsearch              " Highlight while searching with / or ?.
set hlsearch               " Keep matches highlighted.
set ignorecase
set smartcase

set lazyredraw             " Don't redraw while executing macros (good performance config)

set number
augroup numbertoggle
  autocmd!
  autocmd BufEnter,FocusGained,InsertLeave * set relativenumber
  autocmd BufLeave,FocusLost,InsertEnter   * set norelativenumber
augroup END

autocmd InsertLeave,WinEnter * set cursorline
autocmd InsertEnter,WinLeave * set nocursorline
" }}}

" Misc {{{
set nocompatible
if has('win32')
    behave mswin
    " Remap a few keys for Windows behavior
    source $VIMRUNTIME/mswin.vim
endif

set clipboard=unnamed
set noeb
set mouse=a

if has('win32')
    set shell=powershell.exe
    set shellcmdflag=-c
endif

set nobackup
set noundofile
set noswapfile

set autoread
set autowriteall
au FocusGained,BufEnter,CursorHold,CursorHoldI * :silent! checktime
au FocusLost,WinLeave * :silent! noautocmd w
autocmd BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif
" }}}

" Utility {{{
command RmCr %s///g
" }}}

" Key binding {{{
let mapleader = ' '

tnoremap <Esc><Esc> <C-\><C-n>

inoremap <C-k> <Up>
inoremap <C-j> <Down>
inoremap <C-h> <Left>
inoremap <C-l> <Right>

nnoremap <C-k> <C-W>k
nnoremap <C-j> <C-W>j
nnoremap <C-h> <C-W>h
nnoremap <C-l> <C-W>l

nnoremap <M-j> 5j
nnoremap <M-k> 5k
nnoremap <M-h> 4h
nnoremap <M-l> 4l

nnoremap <M-,>   :bp<cr>
nnoremap <M-.>   :bn<cr>
nnoremap <C-tab> :b#<cr>
inoremap <C-tab> :b#<cr>
xnoremap <C-tab> :b#<cr>
nnoremap <Leader>x :b#<cr>

nnoremap [e :cnext<cr>
nnoremap ]e :cprevious<cr>

nnoremap <C-n> :nohl<cr>
nnoremap <Leader>w :update<cr>

nnoremap H ^
nnoremap L $
nnoremap Y y$

nnoremap p p=']
nnoremap P P=']

nnoremap <M-S-j>  :<c-u>execute 'move +'. v:count1<cr>
nnoremap <M-S-k>  :<c-u>execute 'move -1-'. v:count1<cr>

nnoremap <M-S-u> m1gUiw`1
inoremap <M-S-u> <Esc>gUiwgi

nnoremap <Leader>o o<esc>
nnoremap <Leader>O O<esc>

inoremap <C-v> <C-r>0
xnoremap <Leader>p c<C-r>0<Esc>b
nnoremap <Leader>p ciw<C-r>0<Esc>b

set grepprg=rg\ --vimgrep\ -S
set grepformat=%f:%l:%c:%m
command! -nargs=+ Rg execute 'silent lgrep! <args> %' | lw | set nowrap
nnoremap <Leader>v :<C-U><C-R>=printf("Rg -e %s ", expand("<cword>"))<CR>

"highlight conflict markers
nnoremap <Leader>gc /^>>>>>>>\\|^<<<<<<<\\|^=======$<CR>

nmap <M-LeftMouse>  *

" search in last selection
nnoremap <Leader>/ /\%V
nnoremap <Leader>* /<C-U><C-R>='\%V' . '\<' . expand('<cword>') . '\>'<CR><CR>
nnoremap <Leader># ?<C-U><C-R>='\%V' . '\<' . expand('<cword>') . '\>'<CR><CR>
" }}}

if g:NvideConf_UsePlugin == 1

if isdirectory(expand(g:NvideConf_PythonVirtualEnv))
    if has('win32')
        let g:python3_host_prog = expand(g:NvideConf_PythonVirtualEnv).'/Scripts/python.exe'
    else
        let g:python3_host_prog = expand(g:NvideConf_PythonVirtualEnv).'/bin/python3'
    endif
endif

" Install Plugins {{{
call plug#begin(g:NvideConf_PluginDirectory)

" ========= color themes ==========
Plug g:NvideConf_PluginDownloadAddr . 'vim-airline/vim-airline'
Plug g:NvideConf_PluginDownloadAddr . 'vim-airline/vim-airline-themes'
Plug g:NvideConf_PluginDownloadAddr . 'olimorris/onedarkpro.nvim'
Plug g:NvideConf_PluginDownloadAddr . 'arcticicestudio/nord-vim'
Plug g:NvideConf_PluginDownloadAddr . 'rmehri01/onenord.nvim', { 'branch': 'main' }
Plug g:NvideConf_PluginDownloadAddr . 'sainnhe/edge'
Plug g:NvideConf_PluginDownloadAddr . 'norcalli/nvim-colorizer.lua'

" ========= utilities ==========
Plug g:NvideConf_PluginDownloadAddr . 'inkarkat/vim-ingo-library' "Vimscript library of common functions
Plug g:NvideConf_PluginDownloadAddr . 'nvim-lua/plenary.nvim' "Lua functions utils

" ========= language and syntax enhancement ==========
Plug g:NvideConf_PluginDownloadAddr . 'nvim-treesitter/nvim-treesitter'
Plug g:NvideConf_PluginDownloadAddr . 'nvim-treesitter/nvim-treesitter-textobjects'
Plug g:NvideConf_PluginDownloadAddr . 'nvim-treesitter/nvim-treesitter-context'
Plug g:NvideConf_PluginDownloadAddr . 'HiPhish/rainbow-delimiters.nvim'
Plug g:NvideConf_PluginDownloadAddr . 'RRethy/vim-illuminate'

" ========= edit enhancement ==========
Plug g:NvideConf_PluginDownloadAddr . 'inkarkat/vim-mark'
Plug g:NvideConf_PluginDownloadAddr . 'bronson/vim-visual-star-search'
Plug g:NvideConf_PluginDownloadAddr . 'lukas-reineke/indent-blankline.nvim'
Plug g:NvideConf_PluginDownloadAddr . 'phaazon/hop.nvim'
Plug g:NvideConf_PluginDownloadAddr . 'jiangmiao/auto-pairs'
Plug g:NvideConf_PluginDownloadAddr . 'kshenoy/vim-signature'
Plug g:NvideConf_PluginDownloadAddr . 'terryma/vim-expand-region'
Plug g:NvideConf_PluginDownloadAddr . 'dhruvasagar/vim-table-mode'
Plug g:NvideConf_PluginDownloadAddr . 'mg979/vim-visual-multi'
Plug g:NvideConf_PluginDownloadAddr . 'junegunn/vim-easy-align'
Plug g:NvideConf_PluginDownloadAddr . 'tpope/vim-surround'
Plug g:NvideConf_PluginDownloadAddr . 'AndrewRadev/linediff.vim'
Plug g:NvideConf_PluginDownloadAddr . 'notomo/gesture.nvim'
Plug g:NvideConf_PluginDownloadAddr . 'numToStr/Comment.nvim'
Plug g:NvideConf_PluginDownloadAddr . 'kevinhwang91/promise-async'
Plug g:NvideConf_PluginDownloadAddr . 'kevinhwang91/nvim-ufo'

" ========= file manager ==========
Plug g:NvideConf_PluginDownloadAddr . 'scrooloose/nerdtree', { 'on': ['NERDTree', 'NERDTreeToggle', 'NERDTreeVCS'] }
Plug g:NvideConf_PluginDownloadAddr . 'Rolv-Apneseth/tfm.nvim'

if g:NvideConf_UseIdeFeature == 1
" ========= IDE features ==========
" requirements:
" - python3 (packages: neovim, pygments)
" - nodejs
" - ctags, gtags
" - ripgrep
" - LSP server (clangd, ccls, ...)
Plug g:NvideConf_PluginDownloadAddr . 'neoclide/coc.nvim', {'branch': 'release'}
Plug g:NvideConf_PluginDownloadAddr . 'Yggdroot/LeaderF', { 'do': ':LeaderfInstallCExtension' }
Plug g:NvideConf_PluginDownloadAddr . 'Yggdroot/LeaderF-marks'
Plug g:NvideConf_PluginDownloadAddr . 'skywind3000/asyncrun.vim'
Plug g:NvideConf_PluginDownloadAddr . 'Bekaboo/dropbar.nvim'

" ========= debugger ==========
Plug g:NvideConf_PluginDownloadAddr . 'mfussenegger/nvim-dap'
Plug g:NvideConf_PluginDownloadAddr . 'nvim-neotest/nvim-nio'
Plug g:NvideConf_PluginDownloadAddr . 'rcarriga/nvim-dap-ui'

" ========= git ==========
Plug g:NvideConf_PluginDownloadAddr . 'tpope/vim-fugitive'
Plug g:NvideConf_PluginDownloadAddr . 'lewis6991/gitsigns.nvim'
Plug g:NvideConf_PluginDownloadAddr . 'rhysd/git-messenger.vim'
Plug g:NvideConf_PluginDownloadAddr . 'f-person/git-blame.nvim'
Plug g:NvideConf_PluginDownloadAddr . 'sindrets/diffview.nvim'

if g:NvideConf_UseDevIcons == 1
Plug g:NvideConf_PluginDownloadAddr . 'ryanoasis/vim-devicons'
endif
if g:NvideConf_CxxSemanticHighlight == 1
Plug g:NvideConf_PluginDownloadAddr . 'jackguo380/vim-lsp-cxx-highlight', { 'for': ['c', 'cpp'] }
endif
call plug#end()

let g:coc_global_extensions = ['coc-syntax', 'coc-word', 'coc-pairs',
    \ 'coc-lists', 'coc-yank', 'coc-spell-checker', 'coc-snippets',
    \ 'coc-json', 'coc-vimlsp', 'coc-python']

endif " g:NvideConf_UseIdeFeature
" }}}

lua <<EOF
require("onedarkpro").setup({
  colors = {
    onedark        = { bg = "#2E3440" },
    red            = "#CE5E8A",
    dark_red       = "#A7535A",
    green          = "#83A78D",
    yellow         = "#FDCB6E",
    dark_yellow    = "#E2C027",
    blue           = "#6CB6EB",
    purple         = "#A29BFE",
    cyan           = "#81ECEC",
    white          = "#D8DEE9",
    black          = "#2E3440",
    grey           = "#3B4252",
    qiubolan       = "#8ABCD1",
    danjianghuang  = "#F9D770",
    caozhuhong     = "#F8EBE6",
    ganlanshilv    = "#B2CF87",
    aibeilv        = "#DFECD5",
    biandouzi      = "#A35C8F",
    diaozhonghua   = "#CE5E8A",
    qionggui       = "#c4d7d6",
  },
  highlights = {
    ["@label.c"]    = { fg = "${danjianghuang}" },
    ["@constant.c"] = { fg = "${cyan}" },
    ["@comment"]    = { italic = true },
    ["@variable"]   = { fg = "${aibeilv}" },
    ["@property"]   = { fg = "${qiubolan}" },
    ["@operator"]   = { fg = "${purple}" },
    ["@function"]   = { fg = "${diaozhonghua}" },
    ["Type"]        = { fg = "${ganlanshilv}" },
    ["Number"]      = { fg = "${danjianghuang}" },
    ["Boolean"]     = { fg = "${danjianghuang}" },
    ["DiagnosticUnderlineInfo"] = { fg = "${yellow}" }
  },
})
EOF

lua <<EOF
local colors = require("onenord.colors").load()

require("onenord").setup({
  custom_highlights = {
    ["@function"]  = { fg = colors.green },
    ["@string"]    = { fg = colors.cyan },
  },
})
EOF

let g:edge_better_performance = 1
let g:edge_style = 'neon'

"colorscheme edge
"colorscheme nord
" colorscheme onenord
silent! colorscheme onedark
" }}}

" Plug Config: airline {{{
let g:airline_theme='onedark'
"let g:airline_theme='edge'
"let g:airline_theme='nord'
let g:airline_detect_modified=1
let g:airline_powerline_fonts = 1
let g:airline#extensions#branch#enabled = 1
let g:airline#extensions#hunks#enabled = 1
let g:airline#extensions#hunks#non_zero_only = 1
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#formatter = 'unique_tail'
" }}}

" Plug Config: plenary.nvim {{{
" Using "flamegraph profile.log > flame.svg" to generate flame graph.
command StartPerf :lua require'plenary.profile'.start("profile.log", {flame = true})
command StopPerf :lua require'plenary.profile'.stop()
" }}}

"" Plug Config: vim-mark {{{
let g:mwDefaultHighlightingPalette = 'extended'
let g:mwDefaultHighlightingNum = 8
let g:mwHistAdd = '/@'
let g:mw_no_mappings = 1
nmap <Leader>h  <Plug>MarkSet
xmap <Leader>h  <Plug>MarkSet
nmap <Leader>H  <Plug>MarkAllClear
nmap <A-n>      <Plug>MarkSearchGroupNext
nmap <A-N>      <Plug>MarkSearchGroupPrev
" }}}

" Plug Config: Comment.nvim {{{
lua require('Comment').setup()
" }}}

" Plug Config: treesitter {{{
if isdirectory(expand(g:NvideConf_PluginDirectory . 'nvim-treesitter'))
lua <<EOF
require'nvim-treesitter.configs'.setup {
  -- One of "all", "maintained" (parsers with maintainers), or a list of languages
  ensure_installed = {"c", "cpp", "bash", "python", "json", "jsonc"},
  highlight = {
    enable = true,            -- false will disable the whole extension
  },
  refactor = {
    highlight_definitions = { enable = false },
  },
  textobjects = {
    move = {
      enable = true,
      goto_next_start = {
        ["]m"] = "@function.outer",
        ["]s"] = "@class.outer",
      },
      goto_previous_start = {
        ["[m"] = "@function.outer",
        ["[s"] = "@class.outer",
      },
    },
    swap = {
      enable = true,
      swap_next = {
        ["<leader>."] = "@parameter.inner",
      },
      swap_previous = {
        ["<leader>,"] = "@parameter.inner",
      },
    },
  },
}
EOF
endif
" }}}

" Plug Config: treesitter-context {{{
if isdirectory(expand(g:NvideConf_PluginDirectory . 'nvim-treesitter-context'))
lua <<EOF
require'treesitter-context'.setup{
  enable = true, -- Enable this plugin (Can be enabled/disabled later via commands)
  max_lines = 50, -- How many lines the window should span. Values <= 0 mean no limit.
  min_window_height = 0, -- Minimum editor window height to enable context. Values <= 0 mean no limit.
  line_numbers = true,
  multiline_threshold = 20, -- Maximum number of lines to show for a single context
  trim_scope = 'outer', -- Which context lines to discard if `max_lines` is exceeded. Choices: 'inner', 'outer'
  mode = 'cursor',  -- Line used to calculate context. Choices: 'cursor', 'topline'
  -- Separator between context and content. Should be a single character string, like '-'.
  -- When separator is set, the context will only show up when there are at least 2 lines above cursorline.
  separator = nil,
  zindex = 20, -- The Z-index of the context window
  on_attach = nil, -- (fun(buf: integer): boolean) return false to disable attaching
}
EOF
endif
" }}}

" Plug Config: rainbow_delimiters {{{
let g:rainbow_delimiters = {
    \ 'strategy': {
        \ '': rainbow_delimiters#strategy.global,
        \ 'vim': rainbow_delimiters#strategy.local,
    \ },
    \ 'query': {
        \ '': 'rainbow-delimiters',
        \ 'lua': 'rainbow-blocks',
    \ },
    \ 'priority': {
        \ '': 110,
        \ 'lua': 210,
    \ },
    \ 'highlight': [
        \ 'RainbowDelimiterRed',
        \ 'RainbowDelimiterYellow',
        \ 'RainbowDelimiterBlue',
        \ 'RainbowDelimiterOrange',
        \ 'RainbowDelimiterGreen',
        \ 'RainbowDelimiterViolet',
        \ 'RainbowDelimiterCyan',
    \ ],
\ }
" }}}

" Plug Config: indent-blankline {{{
let g:indent_blankline_use_treesitter = v:true
let g:indent_blankline_show_current_context = v:true
" }}}

" Plug Config: vim-visual-multi {{{
let g:VM_maps = {}
let g:VM_maps['Find Under']         = '<M-m>'
let g:VM_maps['Find Subword Under'] = '<M-m>'
nmap <C-LeftMouse>    <Plug>(VM-Mouse-Cursor)
nmap <C-RightMouse>   <Plug>(VM-Mouse-Word)
nmap <M-C-RightMouse> <Plug>(VM-Mouse-Column)
" }}}

" Plug Config: EasyAlign {{{
" Start interactive EasyAlign in visual mode (e.g. vipga)
xmap ga <Plug>(EasyAlign)
" Start interactive EasyAlign for a motion/text object (e.g. gaip)
nmap ga <Plug>(EasyAlign)
" }}}

" Plug Config: AutoPairs {{{
let g:AutoPairsShortcutToggle = ''
" }}}

" Plug Config: asyncrun {{{
if isdirectory(expand(g:NvideConf_PluginDirectory . 'asyncrun.vim'))
let g:asyncrun_open = 12
let g:asyncrun_rootmarks = ['.svn', '.git', 'build.xml']
let g:asyncrun_status = ''
if isdirectory(expand(g:NvideConf_PluginDirectory . 'vim-airline'))
let g:airline_section_error = airline#section#create_right(['%{g:asyncrun_status}'])
endif
nnoremap <A-p> :call asyncrun#quickfix_toggle(9)<cr>
nnoremap <Leader>m :<C-U><C-R>=printf("AsyncRun -cwd=<root> %s", g:Nvide_BuildCmd)<CR>
endif
" }}}

" Plug Config: gesture.nvim {{{
if isdirectory(expand(g:NvideConf_PluginDirectory . 'gesture.nvim'))
nnoremap <silent> <RightMouse>   <Nop>
nnoremap <silent> <RightDrag>    <Cmd>lua require("gesture").draw()<CR>
nnoremap <silent> <RightRelease> <Cmd>lua require("gesture").finish()<CR>
lua << EOF
local gesture = require('gesture')
gesture.register({
  name = "go forward",
  inputs = { gesture.right() },
  action = [[lua vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-i>", true, false, true), "n", true)]]
})
gesture.register({
  name = "go back",
  inputs = { gesture.left() },
  action = [[lua vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-o>", true, false, true), "n", true)]]
})
EOF
endif
" }}}

" Plug Config: hop.nvim {{{
if isdirectory(expand(g:NvideConf_PluginDirectory . 'hop.nvim'))
lua << EOF
require'hop'.setup()
EOF
nnoremap <Leader><Leader>  :HopWord<cr>
nnoremap <Leader>j         :HopChar1<cr>
nnoremap g/                :HopPattern<cr>
endif
"}}}

if g:NvideConf_UseIdeFeature == 1

" Plug Config: gitsigns.nvim {{{
if isdirectory(expand(g:NvideConf_PluginDirectory . 'gitsigns.nvim'))
lua << EOF
require('gitsigns').setup{
  on_attach = function(bufnr)
    local gs = package.loaded.gitsigns

    local function map(mode, l, r, opts)
      opts = opts or {}
      opts.buffer = bufnr
      vim.keymap.set(mode, l, r, opts)
    end

    -- Navigation
    map('n', ']c', function()
      if vim.wo.diff then return ']c' end
      vim.schedule(function() gs.next_hunk() end)
      return '<Ignore>'
    end, {expr=true})

    map('n', '[c', function()
      if vim.wo.diff then return '[c' end
      vim.schedule(function() gs.prev_hunk() end)
      return '<Ignore>'
    end, {expr=true})

    -- Actions
    map({'n', 'v'}, 'gs', ':Gitsigns stage_hunk<CR>')
    map({'n', 'v'}, 'gS', ':Gitsigns reset_hunk<CR>')
    map('n', '<leader>gu', gs.undo_stage_hunk)
    map('n', '<leader>gp', gs.preview_hunk)
    map('n', '<leader>gd', gs.diffthis)
    map('n', '<leader>gD', function() gs.diffthis('~') end)
    map('n', '<leader>td', gs.toggle_deleted)

    -- Text object
    map({'o', 'x'}, 'ih', ':<C-U>Gitsigns select_hunk<CR>')
  end
}
EOF
endif
" }}}

" Plug Config: git-blame.nvim {{{
let g:gitblame_message_template = '   <author> <committer-date> • <summary>'
let g:gitblame_date_format = '%Y-%m-%d'
" }}}

" Plug Config: git-messenger {{{
let g:git_messenger_date_format = '%Y-%m-%d %H:%M %z'
" }}}

" Plug Config: NerdTree {{{
nnoremap <Leader>e :NERDTreeToggle<CR>
nnoremap <Leader>l :NERDTree %<CR>
nnoremap <Leader>E :NERDTreeVCS <C-R>=expand('%:p:h')<CR><CR>
" }}}

" Plug Config: Leaderf {{{
let g:Lf_ShowDevIcons = g:NvideConf_UseDevIcons
let g:Lf_Gtagslabel = g:NvideConf_Lf_Gtagslabel
let g:Lf_GtagsStoreInProject = g:NvideConf_Lf_GtagsStoreInProject
let g:Lf_RootMarkers = g:NvideConf_Lf_RootMarkers
let g:Lf_WorkingDirectoryMode = 'c'
let g:Lf_IgnoreCurrentBufferName = 1
let g:Lf_UseVersionControlTool = 0
let g:Lf_WindowHeight = 0.31
let g:Lf_HideHelp = 1
let g:Lf_IgnoreCurrentBufferName = 1
let g:Lf_CacheDirectory = expand('~/.vim/cache')
let g:Lf_NumberOfCache = 50
let g:Lf_NeedCacheTime = 1
let g:Lf_ShowRelativePath = 1
let g:Lf_DefaultMode = 'NameOnly'
let g:Lf_PreviewResult = {'File': 0, 'Buffer': 0, 'Function': 0, 'Tag': 0, 'Rg': 0, 'Line':1}
let g:Lf_ReverseOrder = 1
let g:Lf_PreviewCode = 1
let g:Lf_PopupWidth = 0.85
let g:Lf_PopupHeight = 0.5
let g:Lf_GtagsAutoGenerate = 0
let g:Lf_GtagsSkipSymlink = 'f'
let g:Lf_GtagsSkipUnreadable = 1
let g:Lf_Gtagsconf = g:NvideConf_Lf_Gtagsconf
let g:Lf_ShortcutF = '<C-P>'
let g:Lf_DiscardEmptyBuffer = 1
let g:Lf_NormalMap = {
    \ "File":   [["<ESC>", ':exec g:Lf_py "fileExplManager.quit()"<CR>']],
    \ "Buffer": [["<ESC>", ':exec g:Lf_py "bufExplManager.quit()"<CR>']],
    \ "Mru":    [["<ESC>", ':exec g:Lf_py "mruExplManager.quit()"<CR>']],
    \ "Tag":    [["<ESC>", ':exec g:Lf_py "tagExplManager.quit()"<CR>']],
    \ "Function":    [["<ESC>", ':exec g:Lf_py "functionExplManager.quit()"<CR>']],
    \ "Colorscheme":    [["<ESC>", ':exec g:Lf_py "colorschemeExplManager.quit()"<CR>']],
    \ }
let g:Lf_CtagsFuncOpts = {
    \ 'c': '--c-kinds=fs',
    \ 'cpp': '--c++-kinds=fc',
    \ 'rust': '--rust-kinds=f',
    \ }

nnoremap <M-r>      :<C-U>Leaderf --recall<CR>
nnoremap <M-o>      :<C-U>Leaderf --next<CR>
nnoremap <M-i>      :<C-U>Leaderf --previous<CR>
nnoremap gf         :LeaderfFileCword<CR>
nnoremap <Leader>b  :Leaderf! buffer<CR>
nnoremap <Leader>ff :Leaderf function --popup<CR>
nnoremap <Leader>ft :Leaderf tag<CR>
nnoremap <Leader>fl :Leaderf line<CR>
nnoremap <Leader>fm :LeaderfMarks<CR>

nnoremap <C-T>      :Leaderf gtags --all --result ctags-mod<CR>
nnoremap <Leader>fr :match Cursor '<C-R><C-W>'<CR> :<C-U><C-R>=printf("Leaderf! gtags --match-path -r %s", expand("<cword>"))<CR><CR>
nnoremap <Leader>fd :<C-U><C-R>=printf("Leaderf! gtags --auto-jump -d %s", expand("<cword>"))<CR><CR>
nnoremap <Leader>fg :<C-U><C-R>=printf("Leaderf! gtags --auto-jump -d ")<CR>

nnoremap <Leader>fsg :<C-U><C-R>=printf("let g:Lf_RootMarkers = ['.git']")<CR><CR>
nnoremap <Leader>fsr :<C-U><C-R>=printf("let g:Lf_RootMarkers = ['.repo']")<CR><CR>
nnoremap <Leader>fsc :<C-U><C-R>=printf("let g:Lf_RootMarkers = ['.root']")<CR><CR>

nnoremap <C-F>      :<C-U><C-R>=printf("Leaderf! rg --wd-mode Ac -S %s ", g:NvideConf_Lf_RgSearchType)<CR>
xnoremap <Leader>f  :<C-U><C-R>=printf("Leaderf! rg --wd-mode Ac -e %s %s -F", leaderf#Rg#visual(), g:NvideConf_Lf_RgSearchType)<CR>
nnoremap <Leader>fw :match Cursor '<C-R><C-W>'<CR> :<C-U><C-R>
    \=printf("Leaderf! rg --match-path --wd-mode Ac -e %s -w %s", expand("<cword>"), g:NvideConf_Lf_RgSearchType)<CR>
nnoremap <Leader>fb :match Cursor '<C-R><C-W>'<CR> :<C-U><C-R>
    \=printf("Leaderf! rg --current-buffer --stayOpen -e %s -w", expand("<cword>"))<CR>
nnoremap <Leader>fa :match Cursor '<C-R><C-W>'<CR> :<C-U><C-R>
    \=printf("Leaderf! rg --append --wd-mode Ac -e '%s'", expand("<cword>"))<CR>
nnoremap <Leader>f= :match Cursor '<C-R><C-W>'<CR> :<C-U><C-R>
    \=printf("Leaderf! rg --match-path --wd-mode Ac -e '\\b%s =' %s", expand("<cword>"), g:NvideConf_Lf_RgSearchType)<CR>
nnoremap <Leader>f( :match Cursor '<C-R><C-W>'<CR> :<C-U><C-R>
    \=printf("Leaderf! rg --match-path --wd-mode Ac -e '\\b%s\\(' %s", expand("<cword>"), g:NvideConf_Lf_RgSearchType)<CR>
nnoremap <Leader>f: :match Cursor '<C-R><C-W>'<CR> :<C-U><C-R>
    \=printf("Leaderf! rg --match-path --wd-mode Ac -e '\\b%s:' %s", expand("<cword>"), g:NvideConf_Lf_RgSearchType)<CR>
" }}}

" Plug Config: coc.nvim {{{
if isdirectory(expand(g:NvideConf_PluginDirectory . 'coc.nvim'))

" Use <c-space> to trigger completion.
if has('nvim')
  inoremap <silent><expr> <c-space> coc#refresh()
else
  inoremap <silent><expr> <c-@> coc#refresh()
endif

" Make <CR> auto-select the first completion item and notify coc.nvim to
" format on enter, <cr> could be remapped by other vim plugin
inoremap <silent><expr> <cr> pumvisible() ? coc#_select_confirm() :
    \ "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>""

function! CheckBackspace() abort
    let col = col('.') - 1
    return !col || getline('.')[col - 1]  =~# '\s'
endfunction

inoremap <silent><expr> <TAB>
      \ coc#pum#visible() ? coc#_select_confirm() :
      \ coc#expandableOrJumpable() ? "\<C-r>=coc#rpc#request('doKeymap', ['snippets-expand-jump',''])\<CR>" :
      \ CheckBackspace() ? "\<TAB>" : coc#refresh()
let g:coc_snippet_next = '<tab>'

function! s:GoToDefinition()
    if CocAction('jumpDefinition')
        return v:true
    endif
    execute("Leaderf! gtags --auto-jump -d " . expand("<cword>"))
endfunction

function! s:FindReference()
    if CocAction('jumpReferences')
        return v:true
    endif
    execute("match Cursor " . expand("<cword>"))
    execute("Leaderf! gtags --match-path -r " . expand("<cword>"))
endfunction

function! s:ShowDocumentation()
    if (index(['vim','help'], &filetype) >= 0)
        execute 'h '.expand('<cword>')
    elseif CocAction('doHover')
        return v:true
    else
        execute 'normal! K'
    endif
endfunction

nmap <F2>            <Plug>(coc-rename)
nmap gd              <Plug>(coc-definition)
nmap gy              <Plug>(coc-type-definition)
nnoremap <Leader>s   :<C-U>CocList symbols<CR>
nnoremap <Leader>cc  :<C-U>CocCommand<CR>
nnoremap <Leader>cl  :<C-U>CocList<CR>
nnoremap K           :call <SID>ShowDocumentation()<CR>
nnoremap <Leader>i   :call <SID>GoToDefinition()<CR>
nnoremap <Leader>r   :call <SID>FindReference()<CR>
nmap <C-LeftMouse>   :call <SID>GoToDefinition()<CR>
nmap <C-M-LeftMouse> :call <SID>FindReference()<CR>
" }}}

" Plug Config: coc-spell-checker {{{
nnoremap <Leader>ca :<C-U>CocCommand cSpell.addWordToDictionary<CR>
vmap <leader>a <Plug>(coc-codeaction-selected)
nmap <leader>a <Plug>(coc-codeaction-selected)
endif
" }}}

" Plug Config: ufo {{{
lua << EOF
vim.o.foldcolumn = '1' -- '0' is not bad
vim.o.foldlevel = 99 -- Using ufo provider need a large value, feel free to decrease the value
vim.o.foldlevelstart = 99
vim.o.foldenable = true
vim.o.fillchars = [[eob: ,fold: ,foldopen:∨,foldsep: ,foldclose:>]]

-- Using ufo provider need remap `zR` and `zM`. If Neovim is 0.6.1, remap yourself
vim.keymap.set('n', 'zR', require('ufo').openAllFolds)
vim.keymap.set('n', 'zM', require('ufo').closeAllFolds)

local handler = function(virtText, lnum, endLnum, width, truncate)
  local newVirtText = {}
  local foldedLines = endLnum - lnum
  local suffix = ("    ↙ %d lines folded "):format(foldedLines)
  local sufWidth = vim.fn.strdisplaywidth(suffix)
  local targetWidth = width - sufWidth
  local curWidth = 0
  for _, chunk in ipairs(virtText) do
    local chunkText = chunk[1]
    local chunkWidth = vim.fn.strdisplaywidth(chunkText)
    if targetWidth > curWidth + chunkWidth then
      table.insert(newVirtText, chunk)
    else
      chunkText = truncate(chunkText, targetWidth - curWidth)
      local hlGroup = chunk[2]
      table.insert(newVirtText, { chunkText, hlGroup })
      chunkWidth = vim.fn.strdisplaywidth(chunkText)
      -- str width returned from truncate() may less than 2nd argument, need padding
      if curWidth + chunkWidth < targetWidth then
        suffix = suffix .. (" "):rep(targetWidth - curWidth - chunkWidth)
      end
      break
    end
    curWidth = curWidth + chunkWidth
  end
  local rAlignAppndx =
    math.max(math.min(vim.opt.textwidth["_value"], width - 1) - curWidth - sufWidth, 0)
  suffix = ("-"):rep(rAlignAppndx) .. suffix
  table.insert(newVirtText, { suffix, "MoreMsg" })
  return newVirtText
end

require('ufo').setup({
    fold_virt_text_handler = handler,
})
EOF

" Plug Config: illuminate {{{
lua << EOF
-- default configuration
require('illuminate').configure({
-- providers: provider used to get references in the buffer, ordered by priority
providers = {
    'lsp',
    'treesitter',
    'regex',
},
-- delay: delay in milliseconds
delay = 50,
-- filetype_overrides: filetype specific overrides.
-- The keys are strings to represent the filetype while the values are tables that
-- supports the same keys passed to .configure except for filetypes_denylist and filetypes_allowlist
filetype_overrides = {},
-- filetypes_denylist: filetypes to not illuminate, this overrides filetypes_allowlist
filetypes_denylist = {
    'dirbuf',
    'dirvish',
    'fugitive',
},
-- filetypes_allowlist: filetypes to illuminate, this is overridden by filetypes_denylist
-- You must set filetypes_denylist = {} to override the defaults to allow filetypes_allowlist to take effect
filetypes_allowlist = {},
-- modes_denylist: modes to not illuminate, this overrides modes_allowlist
-- See `:help mode()` for possible values
modes_denylist = {},
-- modes_allowlist: modes to illuminate, this is overridden by modes_denylist
-- See `:help mode()` for possible values
modes_allowlist = {},
-- providers_regex_syntax_denylist: syntax to not illuminate, this overrides providers_regex_syntax_allowlist
-- Only applies to the 'regex' provider
-- Use :echom synIDattr(synIDtrans(synID(line('.'), col('.'), 1)), 'name')
providers_regex_syntax_denylist = {},
-- providers_regex_syntax_allowlist: syntax to illuminate, this is overridden by providers_regex_syntax_denylist
-- Only applies to the 'regex' provider
-- Use :echom synIDattr(synIDtrans(synID(line('.'), col('.'), 1)), 'name')
providers_regex_syntax_allowlist = {},
-- under_cursor: whether or not to illuminate under the cursor
under_cursor = true,
-- large_file_cutoff: number of lines at which to use large_file_config
-- The `under_cursor` option is disabled when this cutoff is hit
large_file_cutoff = nil,
-- large_file_config: config to use for large files (based on large_file_cutoff).
-- Supports the same keys passed to .configure
-- If nil, vim-illuminate will be disabled for large files.
large_file_overrides = nil,
-- min_count_to_highlight: minimum number of matches required to perform highlighting
min_count_to_highlight = 1,
-- should_enable: a callback that overrides all other settings to
-- enable/disable illumination. This will be called a lot so don't do
-- anything expensive in it.
should_enable = function(bufnr) return true end,
-- case_insensitive_regex: sets regex case sensitivity
case_insensitive_regex = false,
})
EOF
"}}}

" Plug Config: dap and dapui {{{
lua << EOF
local dap = require("dap")
dap.adapters.cppdbg = {
  id = 'cppdbg',
  type = 'executable',
  command = '~/bin/debugAdapters/bin/OpenDebugAD7',
}
require('dap.ext.vscode').load_launchjs(nil, { cppdbg = {'c', 'cpp'} })

require("dapui").setup()
EOF
nnoremap <F5> :lua require("dapui").toggle()<CR>
"}}}

" Plug Config: tfm {{{
lua << EOF
require("tfm").setup {
  file_manager = "yazi",
  replace_netrw = true,
  enable_cmds = true,
  ui = {
    border = "rounded",
    height = 1,
    width = 1,
    x = 0.5,
    y = 0.5,
  },
}
EOF
nnoremap <Leader>t :Tfm<CR>
nnoremap <Leader>tv :TfmVsplit<CR>
nnoremap <Leader>th :TfmSplit<CR>
"}}}

endif " g:NvideConf_UseIdeFeature

endif " g:NvideConf_UsePlugin

" vim: set ft=vim fdm=marker fmr={{{,}}}:
