" Basic Settings
set nocompatible              " Disable Vi compatibility
set encoding=utf-8            " Set encoding to UTF-8
set fileencoding=utf-8
set backspace=indent,eol,start " Make backspace work as expected

" UI Settings
set number                    " Show line numbers
set relativenumber           " Show relative line numbers
set cursorline               " Highlight current line
set showcmd                  " Show command in bottom bar
set wildmenu                 " Visual autocomplete for command menu
set lazyredraw              " Redraw only when needed
set showmatch               " Highlight matching brackets
set ruler                   " Show cursor position

" Search Settings
set incsearch               " Search as characters are entered
set hlsearch                " Highlight search matches
set ignorecase              " Case insensitive search
set smartcase               " But case sensitive when uppercase present

" Indentation
set tabstop=4               " Number of visual spaces per TAB
set softtabstop=4           " Number of spaces in tab when editing
set shiftwidth=4            " Number of spaces for autoindent
set expandtab               " Convert tabs to spaces
set autoindent              " Auto indent new lines
set smartindent             " Smart indent for code

" File Type Specific Settings
filetype plugin indent on
autocmd FileType python setlocal shiftwidth=4 tabstop=4 softtabstop=4
autocmd FileType javascript,typescript,json,html,css setlocal shiftwidth=2 tabstop=2 softtabstop=2
autocmd FileType yaml setlocal shiftwidth=2 tabstop=2 softtabstop=2

" Syntax Highlighting
syntax enable

" Key Mappings
let mapleader = ","         " Set leader key to comma

" Clear search highlighting
nnoremap <leader><space> :nohlsearch<CR>

" Move between windows
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" Backup and Swap Files
set nobackup
set nowritebackup
set noswapfile

" Status Line
set laststatus=2            " Always show status line
set statusline=%F%m%r%h%w[%L][%{&ff}]%y[%p%%][%04l,%04v]

" Mouse Support
set mouse=a                 " Enable mouse in all modes

" Clipboard
set clipboard=unnamedplus   " Use system clipboard

" Auto-reload files when changed outside vim
set autoread

" Remember cursor position
autocmd BufReadPost *
    \ if line("'\"") >= 1 && line("'\"") <= line("$") |
    \   exe "normal! g`\"" |
    \ endif