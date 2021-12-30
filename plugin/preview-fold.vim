" nnoremap l <cmd>call PreviewFold()<cr>
" function! PreviewFold()
"     if foldclosed('.') != -1 && g:fold_preview_cocked
"         let g:fold_preview_cocked = v:false
"         lua require('pretty-fold.preview').show_preview()
"     else
"         normal! zvl
"     endif
" endfunction

" " The same, but via <expr>.
" nnoremap <expr> l PreviewFold()
" function! PreviewFold()
"     if foldclosed('.') != -1 && g:fold_preview_cocked
"         let g:fold_preview_cocked = v:false
"         return "\<cmd>lua require('pretty-fold.preview').show_preview()\<cr>"
"     else
"         return 'zvl'
"     endif
" endfunction

" au CursorHold * lua require('pretty-fold.preview').show_preview()
