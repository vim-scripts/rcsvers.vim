" rcsvers.vim
" Author: Roger Pilkey (rpilkey at magma.ca)
" Last Change: 2003 Feb 12
" Version: 1.0
"
" Vim plugin for automatically saving backup versions in rcs 
" whenever a file is saved.
"
" What's RCS? See http://www.gnu.org/software/rcs/rcs.html
"
" Don't use this if you really use RCS as your production file control, it
" will add versions like crazy.
"
" If you're using Microsoft Windows, then the rcs programs are available by
" installing WinCVS (http://www.wincvs.org/)
"
" rcs-menu.vim by Jeff Lanzarotta is handy to have along with this.
" 
"
augroup rcsvers
   au!
   let s:types = "*"
   exe "au BufWritePost,FileWritePost,FileAppendPost " . s:types . " call s:rcsvers_post()"
augroup END


function! s:rcsvers_post()
	if ! isdirectory("RCS")
		let l:val = system("mkdir RCS")
	endif
	let l:rcsfile = "RCS/" . bufname("%") . ",v"
	if (getfsize(l:rcsfile) == -1)
		let l:cmd = "ci -i -t- "
	else
		let l:cmd = "ci -mvim_rcsvers "
	endif
	let l:cmd = l:cmd . bufname("%") 
	let l:val = system(l:cmd)

	"check out with no keyword substitution.
	"if you want keyword substitution, drop the -ko
	"I did this so that this backup hack wouldn't interfere
	"with your real source code control keywords
	let l:cmd = "co -q -ko -l "
	let l:cmd = l:cmd . bufname("%")
	let l:val = system(l:cmd)
endfunction

