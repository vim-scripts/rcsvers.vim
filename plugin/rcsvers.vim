" rcsvers.vim
" Maintainer: Roger Pilkey (rpilkey at magma.ca)
" $Author: bert $
" $Date: 2003/02/20 10:04:15 $
" $Revision: 1.4 $
" $Id: rcsvers.vim,v 1.4 2003/02/20 10:04:15 bert Exp bert $
"
"
" Vim plugin for automatically saving backup versions in rcs
" whenever a file is saved.
"
" What's RCS? See http://www.gnu.org/software/rcs/rcs.html
"
" Be careful if you really use RCS as your production file control, it
" will add versions like crazy.
"
" If you're using Microsoft Windows, then the rcs programs are available by
" installing WinCVS (http://www.wincvs.org/), and putting the wincvs directory
" in your path.
"
" rcs-menu.vim by Jeff Lanzarotta is handy to have along with this (vimscript #41).
"
" To Do: add version/diff viewing tools like savevers.vim
"
" Changes:
" 1.5   add l:skipfilename to allow exclusion of directories from versioning.
"       and FIX for editing in current directory with local RCS directory.
" 1.4   FIX editing files not in current directory.
" 1.3 	option to select the rcs directory,
" 		and better comments thanks to Juan Frias
" 
if exists("loaded_rcsvers")
	finish
endif
let loaded_rcsvers = 1

augroup rcsvers
	au!
	let s:types = "*"
	exe "au BufWritePost,FileWritePost,FileAppendPost " . s:types . " call s:rcsvers_post()"
augroup END


function! s:rcsvers_post()
	"set the directory separator
	if has("win32") || has("win16") || has("dos32") || has("dos16") || has("os2")
		let l:sep = "\\"
		let l:skipfilename = "_novimrcs"
	else
		" BUG: attention macos has ":"
		let l:sep = "\/"
		let l:skipfilename = ".novimrcs"
	endif

	" Exclude directories from versioning, by putting skipfile there.
	if filereadable( expand("%:p:h") . l:sep . l:skipfilename )
		return
	endif

	" Path where RCS files will be saved to:

	" a. Use this to have one directory for all rcs files
	"    (duplicate filenames may cause a problem, use the unique suffix below)
	" BUG: maybe add the files path, when editing a file not in current directory.
	let l:rcsdir = $VIM . l:sep . "RCSFiles"
	
	" b. Use the RCS directory in the files directory
	" let l:rcsdir = expand("%:p:h") . l:sep . "RCS"

	" RCS file suffix	
	" a. Create a suffix to make unique rcs files when files that are
	"    in different directories have the same name
	let l:suffix = "," . expand("%:p:h:gs?\[:/ \\\\]?_?")

	" b. use the regular suffix
	" let l:suffix = ",v"

	" Create RCS dir if it doesn't exist
	if ! isdirectory(l:rcsdir)
		let l:returnval = system("mkdir " . l:rcsdir)
		if ( l:returnval != "" )
			let l:err = "Could not create rcs directory: " . l:rcsdir . "\nThe error was: " . l:returnval
			let l:returnval = confirm(l:err, "&Okay")
		endif
	endif
	
	" Generate name of RCS file
	let l:rcsfile = l:rcsdir . l:sep . expand("%:t") . l:suffix

	" ci options are as follows:
	" -i        Initial check in
	" -l        Check out and lock file after check in.
	" -t-       File description at initial check in.
	" -x        Suffix to use for rcs files.
	" -m        Log message

	if (getfsize(l:rcsfile) == -1)
		" Initial check-in note: -i -t-
		let l:cmd = "ci -i -l -t- -x" . l:suffix
	else
		" Subsequent check-ins note: -m
		let l:cmd = "ci -l -mvim_rcsvers -x" . l:suffix
	endif
	" Build command string <command> <filename> <rcs file>
	let l:cmd = l:cmd . " " . bufname("%") . " " . l:rcsfile
	let l:returnval = system(l:cmd)

endfunction
