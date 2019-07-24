let g:vimtex_fold_enabled = 1
let g:vimtex_view_method = 'zathura'
let g:vimtex_compiler_latexmk = {
  \ 'options' : [
  \   '-shell-escape',
  \   '-xelatex',
  \   '-verbose',
  \   '-file-line-error',
  \   '-interaction=nonstopmode'
  \ ]
  \}
let g:tex_flavor = 'latex'

let NERDTreeShowHidden=0
let NERDChristmasTree=1
let NERDTreeShowBookmarks=0
let NERDTreeMinimalUI=0
let NERDTreeIgnore=['\.png$', '\.jpg$', '\.gif$', '\.tmp$', '\.swp$', '\.a$', '\.gls$', '\.glg$', '\.alg$', '\.acr$', '\.xdy$', '\.aux$', '\.pdf$', '\.glo$', '\.fls$', '\.acn$']
let NERDTreeStatusline= '-1'
let g:NERDTreeWinSize = '40'

let g:NERDTreeIndicatorMapCustom = {
    \ "Modified"  : "✹",
    \ "Staged"    : "✚",
    \ "Untracked" : "✭",
    \ "Renamed"   : "➜",
    \ "Unmerged"  : "═",
    \ "Deleted"   : "✖",
    \ "Dirty"     : "✗",
    \ "Clean"     : "✔︎",
    \ "Unknown"   : "?"
    \ }

let g:ctrlp_custom_ignore = {
 \ 'dir':  '\v[\/]\.(git|hg|svn)$',
 \ 'file': '\v\.(png|jpg|gif|tmp|swp|a|gls|glg|alg|acr|xdy|aux|pdf|glo|fls|acn|toc|out|log|fdb_latexmk|latexmain|run.xml|blg|bbl|bcf)$',
 \ }

let g:lightline = {
    \ 'colorscheme': 'seoul256',
    \ 'component': {
    \   'readonly': '%{&readonly?"RO":""}',
    \   'modified': '%{&filetype=="help"?"":&modified?"+":&modifiable?"":"-"}',
    \ }
    \ }

" always show statusline
set laststatus=2

nmap <C-o> :NERDTreeToggle<cr>

let mapleader = " "
let maplocalleader = " "
let localleader = " "
let g:mapleader = " "

" allows vertical line traversal over wrapped lines
nmap j gj
nmap k gk

nnoremap  <Leader>w :w<CR>
nnoremap  <Leader>q :q<CR>
nnoremap  <Leader>Q :wq<CR>

" Space, Enter to remove search highlight
nnoremap  <silent> <leader><cr> :noh<cr>

" Window resizing
nnoremap <silent> <Leader>+ :exe "resize " . (winheight(0) * 3/2)<CR>
nnoremap <silent> <Leader>- :exe "resize " . (winheight(0) * 2/3)<CR>

" Copy & Paste to system clipboard with <Space>p and <Space>y
vnoremap <Leader>y "+y
vnoremap <Leader>d "+d

" paste from the clipboard
vnoremap <Leader>p "+p
vnoremap <Leader>P "+P

" same as above, but for normal mode
nnoremap <Leader>d "+d
nnoremap <Leader>y "+y
nnoremap <Leader>p "+p
nnoremap <Leader>P "+P

" Save cursor position
augroup resCur
  autocmd!
  autocmd BufReadPost * call setpos(".", getpos("'\""))
augroup END

" Close vim if the only window left open is a NERDTree.
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif

" .NFO specific
au BufReadPre *.nfo call SetFileEncodings('cp437')|set ambiwidth=single
au BufReadPost *.nfo call RestoreFileEncodings()

" Always start at 1:1 when writing git commits
autocmd BufEnter *
    \ if &filetype == 'gitcommit' |
    \   call setpos('.', [0, 1, 1]) |
    \ endif

" 'set wrap lbr' in all .tex files
autocmd BufNewFile,BufReadPost *.tex set wrap lbr
set wrap lbr

set nocompatible
filetype off
set number
set noerrorbells
filetype plugin indent on
set list
set listchars=tab:\┊\ ,eol:¬,trail:·,extends:→,precedes:←
hi SpecialKey ctermbg=5 ctermfg=8

set mouse=a

set exrc             " Source .vimrc from working directory...
set secure           " ... but don't let them execute system commands!
set autoread         " Reload file when changed externally
set noswapfile       " Text files don't use _that_ much memory
set undofile         " Persistent undos?
set undodir=~/.vim/undodir
set history=1000

set expandtab        " Expand tab characters to space characters
set shiftwidth=4     " One tab is 4 spaces

" Round up to the nearest tab
set shiftround
set tabstop=4
set softtabstop=4    " Easy removal of an indention level

set autoindent       " Automatically copy the previous indent level
set lazyredraw       " Good performance boost when executing macros
set backspace=indent,eol,start

" Searching
set ignorecase       " Search is not case sensitive
set smartcase        " Will override some ignorecase properties, when using caps it will do a special search.
set incsearch        " Search hits stepping
set hlsearch         " Clear current seatch highlight upon another search

" UI
set ffs=unix,dos,mac " Prioritize Unix as the standard file type
set scrolloff=7      " The screen will only scroll when the cursor is 7 characters from the top/bottom
set wildmenu         " Enable autocomplete menu when in command mode (':')
set hidden           " Abandon buffer when closed

set showmatch        " Will highlight matching brackets
set mat=2            " How long the the highlight will last

" Folding
set foldmethod=indent   " fold based on indent
set foldnestmax=10      " deepest fold is 10 levels
set nofoldenable        " don't fold by default
set foldlevel=1

" open new slip panes to right and bottom, which feels more natural
set splitbelow
set splitright

" gvim options:  remove the toolbar(s)
set guioptions-=L
set guioptions-=T
set guioptions-=r
set guioptions-=m

syntax enable
let g:seoul256_background = 236 " darker, bitte!
colorscheme seoul256
