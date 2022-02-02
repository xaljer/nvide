" Set default configurations {{{
let g:NvideConf_UseIdeFeature = 1
let g:NvideConf_UsePlugin = 1
let g:NvideConf_Lf_GtagsStoreInProject = 0
let g:NvideConf_Lf_Gtagslabel = "native-pygments"
let g:NvideConf_Lf_RootMarkers = ['.repo', '.root', '.svn', '.git']
let g:NvideConf_Lf_RgSearchType = ''
let g:NvideConf_CxxSemanticHighlight = 0
let g:Nvide_BuildCmd = "make"
let g:NvideConf_PythonVirtualEnv = ''
let g:NvideConf_UseDevIcons = 1
let g:NvideConf_PluginDirectory = join([stdpath("config"), "plugged"], "/")
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
set updatetime=150         " make virtual text real-time update

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
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'joshdick/onedark.vim'
Plug 'arcticicestudio/nord-vim'
Plug 'sainnhe/edge'

" ========= language and syntax enhancement ==========
Plug 'nvim-treesitter/nvim-treesitter'
Plug 'nvim-treesitter/nvim-treesitter-refactor'
Plug 'nvim-treesitter/nvim-treesitter-textobjects'
Plug 'romgrk/nvim-treesitter-context'

" ========= edit enhancement ==========
Plug 'inkarkat/vim-ingo-library'
Plug 'inkarkat/vim-mark'
Plug 'bronson/vim-visual-star-search'
Plug 'luochen1990/rainbow'
Plug 'Yggdroot/indentLine'
Plug 'easymotion/vim-easymotion'
Plug 'jiangmiao/auto-pairs'
Plug 'kshenoy/vim-signature'
Plug 'terryma/vim-expand-region'
Plug 'dhruvasagar/vim-table-mode'
Plug 'mg979/vim-visual-multi'
Plug 'junegunn/vim-easy-align'
Plug 'tpope/vim-surround'
Plug 'AndrewRadev/linediff.vim'
Plug 'notomo/gesture.nvim'

if g:NvideConf_UseIdeFeature == 1
" ========= IDE features ==========
" requirements:
" - python3 (packages: neovim, pygments)
" - nodejs, yarn
" - ctags, gtags
" - ripgrep
" - LSP server (clangd, ccls, ...)
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'Yggdroot/LeaderF', { 'do': ':LeaderfInstallCExtension' }
Plug 'Yggdroot/LeaderF-marks'

Plug 'tpope/vim-fugitive'
Plug 'airblade/vim-gitgutter'
Plug 'rhysd/git-messenger.vim'
Plug 'f-person/git-blame.nvim'
Plug 'skywind3000/asyncrun.vim'
Plug 'w0rp/ale'
Plug 'scrooloose/nerdtree', { 'on': ['NERDTreeToggle', 'NERDTreeVCS'] }

if g:NvideConf_UseDevIcons == 1
Plug 'ryanoasis/vim-devicons'
endif
if g:NvideConf_CxxSemanticHighlight == 1
Plug 'jackguo380/vim-lsp-cxx-highlight', { 'for': ['c', 'cpp'] }
endif
call plug#end()

let g:coc_global_extensions = ['coc-syntax', 'coc-word', 'coc-pairs',
    \ 'coc-lists', 'coc-yank', 'coc-spell-checker', 'coc-snippets',
    \ 'coc-json', 'coc-vimlsp', 'coc-python']

endif " g:NvideConf_UseIdeFeature
" }}}

" Plug Config: colorscheme {{{
let g:onedark_color_overrides = {
    \ "red":            { "gui": "#e84393", "cterm": "204", "cterm16": "1" },
    \ "dark_red":       { "gui": "#a7535a", "cterm": "196", "cterm16": "9" },
    \ "green":          { "gui": "#41b349", "cterm": "114", "cterm16": "2" },
    \ "yellow":         { "gui": "#fdcb6e", "cterm": "180", "cterm16": "3" },
    \ "dark_yellow":    { "gui": "#e2c027", "cterm": "173", "cterm16": "11" },
    \ "blue":           { "gui": "#6cb6eb", "cterm": "39", "cterm16": "4" },
    \ "purple":         { "gui": "#a29bfe", "cterm": "170", "cterm16": "5" },
    \ "cyan":           { "gui": "#81ecec", "cterm": "38", "cterm16": "6" },
    \ "white":          { "gui": "#d8dee9", "cterm": "145", "cterm16": "7" },
    \ "black":          { "gui": "#2e3440", "cterm": "235", "cterm16": "0" },
    \ "visual_black":   { "gui": "NONE",    "cterm": "NONE", "cterm16": "0" },
    \ "comment_grey":   { "gui": "#a4b0be", "cterm": "59", "cterm16": "15" },
    \ "gutter_fg_grey": { "gui": "#4B5263", "cterm": "238", "cterm16": "15" },
    \ "cursor_grey":    { "gui": "#2C323C", "cterm": "236", "cterm16": "8" },
    \ "visual_grey":    { "gui": "#3E4452", "cterm": "237", "cterm16": "15" },
    \ "menu_grey":      { "gui": "#3E4452", "cterm": "237", "cterm16": "8" },
    \ "special_grey":   { "gui": "#3B4048", "cterm": "238", "cterm16": "15" },
    \ "vertsplit":      { "gui": "#181A1F", "cterm": "59", "cterm16": "15" },
    \}

let g:edge_better_performance = 1
let g:edge_style = 'neon'

"colorscheme edge
"colorscheme nord
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

" Plug Config: vim-mark {{{
let g:mwDefaultHighlightingPalette = 'extended'
let g:mwDefaultHighlightingNum = 8
let g:mwHistAdd = '/@'
let g:mw_no_mappings = 1
nmap <Leader>h  <Plug>MarkSet
xmap <Leader>h  <Plug>MarkSet
nmap <Leader>H  <Plug>MarkAllClear
nmap <Leader>/  <Plug>MarkRegex
nmap <A-n>      <Plug>MarkSearchGroupNext
nmap <A-b>      <Plug>MarkSearchGroupPrev
" }}}

" Plug Config: rainbow {{{
let g:rainbow_active = 1
let g:rainbow_conf = {
    \   'guifgs': ['royalblue2', 'darkorange3', 'seagreen3', 'firebrick'],
    \   'ctermfgs': ['lightblue', 'lightyellow', 'lightcyan', 'lightmagenta'],
    \   'operators': '_,_',
    \   'parentheses': ['start=/(/ end=/)/ fold', 'start=/\[/ end=/\]/ fold', 'start=/{/ end=/}/ fold'],
    \   'separately': {
    \       '*': {},
    \       'tex': {
    \           'parentheses': ['start=/(/ end=/)/', 'start=/\[/ end=/\]/'],
    \       },
    \       'lisp': {
    \           'guifgs': ['royalblue3', 'darkorange3', 'seagreen3', 'firebrick', 'darkorchid3'],
    \       },
    \       'vim': {
    \           'parentheses': ['start=/(/ end=/)/', 'start=/\[/ end=/\]/', 'start=/{/ end=/}/ fold', 'start=/(/ end=/)/ containedin=vimFuncBody', 'start=/\[/ end=/\]/ containedin=vimFuncBody', 'start=/{/ end=/}/ fold containedin=vimFuncBody'],
    \       },
    \       'html': {
    \           'parentheses': ['start=/\v\<((area|base|br|col|embed|hr|img|input|keygen|link|menuitem|meta|param|source|track|wbr)[ >])@!\z([-_:a-zA-Z0-9]+)(\s+[-_:a-zA-Z0-9]+(\=("[^"]*"|'."'".'[^'."'".']*'."'".'|[^ '."'".'"><=`]*))?)*\>/ end=#</\z1># fold'],
    \       },
    \       'css': 0,
    \   }
    \}
" }}}

" Plug Config: treesitter {{{
if isdirectory(expand(g:NvideConf_PluginDirectory . '/nvim-treesitter'))
lua <<EOF
require'nvim-treesitter.configs'.setup {
  -- One of "all", "maintained" (parsers with maintainers), or a list of languages
  ensure_installed = {"c", "cpp", "bash", "python", "json", "json5", "jsonc", "markdown"},
  highlight = {
    enable = true,            -- false will disable the whole extension
  },
  refactor = {
    highlight_definitions = { enable = true },
  },
  textobjects = {
    move = {
      enable = true,
      goto_next_start = {
        ["]m"] = "@function.outer",
      },
      goto_previous_start = {
        ["[m"] = "@function.outer",
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

" Plug Config: indentLine {{{
let g:indentLine_char = '┆'
" }}}

" Plug Config: EasyMotion {{{
let g:EasyMotion_smartcase = 1
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
if isdirectory(expand(g:NvideConf_PluginDirectory . '/asyncrun.vim'))
let g:asyncrun_open = 12
let g:asyncrun_rootmarks = ['.svn', '.git', 'build.xml']
let g:asyncrun_status = ''
if isdirectory(expand(g:NvideConf_PluginDirectory . '/vim-airline'))
let g:airline_section_error = airline#section#create_right(['%{g:asyncrun_status}'])
endif
nnoremap <A-p> :call asyncrun#quickfix_toggle(9)<cr>
nnoremap <Leader>m :<C-U><C-R>=printf("AsyncRun -cwd=<root> %s", g:Nvide_BuildCmd)<CR>
endif
" }}}

" Plug Config: gesture.nvim {{{
if isdirectory(expand(g:NvideConf_PluginDirectory . 'gesture.nvim'))
nnoremap <silent> <RightMouse>   <Nop>
nnoremap <silent> <RightDrag>    <Cmd>Gesture draw<CR>
nnoremap <silent> <RightRelease> <Cmd>Gesture finish<CR>
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

if g:NvideConf_UseIdeFeature == 1

" Plug Config: vim-gitgutter {{{
let g:gitgutter_signs = 0
nmap gs <Plug>(GitGutterStageHunk)
nmap gS <Plug>(GitGutterUndoHunk)
xmap gs <Plug>(GitGutterStageHunk)
xmap gS <Plug>(GitGutterUndoHunk)
nmap <Leader>gp <Plug>(GitGutterPreviewHunk)
nmap <Leader>gf :GitGutterFold<CR>

function! GitGutterNextHunkCycle()
  let line = line('.')
  silent! GitGutterNextHunk
  if line('.') == line
    1
    GitGutterNextHunk
  endif
endfunction
nmap ]c :call GitGutterNextHunkCycle()<CR>
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
let g:Lf_NumberOfCache = 30
let g:Lf_NeedCacheTime = 1
let g:Lf_ShowRelativePath = 1
let g:Lf_DefaultMode = 'NameOnly'
let g:Lf_PreviewResult = {'Function':0, 'Tag':0, 'Rg':0, 'Line':1}
let g:Lf_ReverseOrder = 1
let g:Lf_PreviewCode = 1
let g:Lf_PopupWidth = 0.85
let g:Lf_PopupHeight = 0.5
let g:Lf_GtagsAutoGenerate = 0
let g:Lf_Gtagsconf = expand('~/gtags.conf')
let g:Lf_ShortcutF = '<C-P>'
let g:Lf_NormalMap = {
    \ "File":   [["<ESC>", ':exec g:Lf_py "fileExplManager.quit()"<CR>']],
    \ "Buffer": [["<ESC>", ':exec g:Lf_py "bufExplManager.quit()"<CR>']],
    \ "Mru":    [["<ESC>", ':exec g:Lf_py "mruExplManager.quit()"<CR>']],
    \ "Tag":    [["<ESC>", ':exec g:Lf_py "tagExplManager.quit()"<CR>']],
    \ "Function":    [["<ESC>", ':exec g:Lf_py "functionExplManager.quit()"<CR>']],
    \ "Colorscheme":    [["<ESC>", ':exec g:Lf_py "colorschemeExplManager.quit()"<CR>']],
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
" Use <TAB> to select the popup menu:
autocmd! CompleteDone * if pumvisible() == 0 | pclose | endif

function! s:check_back_space() abort
    let col = col('.') - 1
    return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" Use tab for trigger completion with characters ahead and navigate.
"inoremap <silent><expr> <TAB>  pumvisible() ? "\<C-n>" :
"    \ <SID>check_back_space() ? "\<TAB>" : coc#refresh()
"inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

" Make <CR> auto-select the first completion item and notify coc.nvim to
" format on enter, <cr> could be remapped by other vim plugin
inoremap <silent><expr> <cr> pumvisible() ? coc#_select_confirm() :
    \ "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>""

inoremap <silent><expr> <TAB>  pumvisible() ? coc#_select_confirm() :
    \ coc#expandableOrJumpable() ? "\<C-r>=coc#rpc#request('doKeymap', ['snippets-expand-jump',''])\<CR>" :
    \ <SID>check_back_space() ? "\<TAB>" : coc#refresh()
let g:coc_snippet_next = '<tab>'

function! s:GoToDefinition()
    if CocAction('jumpDefinition')
        return v:true
    endif
    execute("Leaderf! gtags --auto-jump -d " . expand("<cword>"))
endfunction

function! s:FindReference()
    if CocAction('jumpReference')
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

" Plug Config: ALE {{{
let g:ale_linters_explicit = 1
let g:ale_echo_delay = 20
let g:ale_lint_delay = 500
let g:ale_echo_msg_format = '[%linter%] %code: %%s'
let g:ale_lint_on_save = 1
let g:ale_lint_on_enter = 1
let g:ale_lint_on_insert_leave = 1
let g:ale_lint_on_text_changed = 'normal'
let g:ale_linters = {
\   'cpp': ['clangtidy'],
\   'c': ['clangtidy'],
\   'python': ['pylint'],
\}
" }}}

endif " g:NvideConf_UseIdeFeature

endif " g:NvideConf_UsePlugin

" vim: set ft=vim fdm=marker fmr={{{,}}}:
