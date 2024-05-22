" Java's syntax highlighting breaks spell check,
" so remove it, for more info see:
" https://github.com/tpope/vim-markdown/issues/89
" \  'java',
let g:markdown_fenced_languages = [
\  'bash=sh',
\  'c',
\  'c++=cpp',
\  'cpp',
\  'go',
\  'html',
\  'javascript',
\  'python',
\  'ruby',
\  'rust',
\]

" auto format markdown files with pandoc
let g:ale_fixers['markdown'] = ['pandoc']
