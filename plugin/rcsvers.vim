" rcsvers.vim
" Original Author: Roger Pilkey (rpilkey at magma.ca)
" Maintainer: Juan Frias (frias.junk at earthlink.net)
" $Author: juanf $
" $Date: 2003/02/24 19:13:56 $
" $Revision: 1.7 $
" $Id: rcsvers.vim,D__Vim_vimfiles_plugin 1.7 2003/02/24 19:13:56 juanf Exp juanf $
"
"--------------------------------------------------------------------------
"
" Please send me any bug so I can keep the script up to date.
"
"--------------------------------------------------------------------------
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
" 1.6   Complete script re-write. added ability to set user options by vimrc
"       and will now allow you to compare to older revision if you have grep
"       and sed installed.
" 1.5   add l:skipfilename to allow exclusion of directories from versioning.
"       and FIX for editing in current directory with local RCS directory.
" 1.4   FIX editing files not in current directory.
" 1.3 	option to select the rcs directory,
" 		and better comments thanks to Juan Frias
"
"--------------------------------------------------------------------------
"
" Options are as follows:
"
" <Leader>rlog
"       This is the default key amp to display the revision log. search
"       for "key" to overwrite this key.
"
"       IMPORTANT: If you are going to use the display/compare log
"                  key you must have "grep" and "sed" installed on
"                  your system as these are used to generate the
"                  revision list.
"
" g:rvCompareProgram
"       This is the program that will be called to compare two files,
"       the temporary file created by the revision log and the current
"       file. The default program is diff. To overwrite use:
"           let g:rvCompareProgram = <your compare program>
"       in your vimrc file. Win32 users you may want to use:
"           let g:rvCompareProgram = start <your program>
"       for an asynchronous run type :help :!start for details.
"
" g:rvDirSeparator
"       Separator to use between paths script will try to auto detect
"       but to overwrite use:
"           let g:rvDirSeparator = <separator>
"       in your vimrc file.
"
" g:rvTempDir
"       This is the temporary directory to create a revision file to
"       compare to. The default is C:\Temp for Dos/win systems and
"       <g:rvDirSeparator>temp for all other systems. The script will
"       automatically append the directory separator to the end, so
"       do not include this. To overwrite defaults use:
"           let g:rvTempDir = <your directory>
"       in your vimrc file.
"
" g:rvSkipVimRcsFileName
"       This is the name of the file the script will look for, if its found
"       in the directory the file is being edited the RCS file will not
"       be written. By default the name is _novimrcs for Dos/win systems
"       and .novimrcs for all other. to overwrite use:
"           let  g:rvSkipVimRcsFileName = <filename>
"       in your vimrc file.
"
" g:rvSaveDirectoryType
"       This specifies how the script will save the RCS files. by default
"       they will be saved under the current directory. To overwrite use:
"           let g:rvSaveDirectoryType = 1
"       in your vimrc file, options are as follows:
"           0 = Save in current directory
"           1 = Single directory for all files
"
" g:rvSaveDirectoryName
"       This specifies the name of the directory where the RCS files will
"       be saved. By default if g:rvSaveDirectoryType = 0 (saving to
"       the current directory) the script will use RCS. If
"       g:rvSaveDirectoryType = 1 (saving all files in a single
"       directory) the script will save them to $VIM/RCSFiles to overwrite
"       the default name use:
"           let g:rvSaveDirectoryName = <my directory name>
"       in your vimrc file.
"
"--------------------------------------------------------------------------


" Load script once
"--------------------------------------------------------------------------
if exists("loaded_rcsvers")
    finish
endif
let loaded_rcsvers = 1


" Default key mapping to generate revision log.
"--------------------------------------------------------------------------
map <Leader>rlog :call <SID>DisplayLog()<cr>


" Set the compare program
"--------------------------------------------------------------------------
if !exists('g:rvCompareProgram')
    let g:rvCompareProgram = "diff"
endif


" Set the directory separator
"--------------------------------------------------------------------------
if !exists('g:rvDirSeparator')
    if has("win32") || has("win16") || has("dos32") || has("dos16") || has("os2")
        let g:rvDirSeparator = "\\"

    elseif has("mac")
        let g:rvDirSeparator = ":"

    else " *nix systems
        let g:rvDirSeparator = "\/"
    endif
endif


" Set the temp directory
"--------------------------------------------------------------------------
if !exists('g:rvTempDir')
    if has("win32") || has("win16") || has("dos32") || has("dos16") || has("os2")
        let g:rvTempDir = "C:\\Temp"
    else
        let g:rvTempDir = g:rvDirSeparator."tmp"
    endif
endif


" Skip vim's rcs file name
"--------------------------------------------------------------------------
if !exists('g:rvSkipVimRcsFileName')
    if has("win32") || has("win16") || has("dos32") || has("dos16") || has("os2")
        let g:rvSkipVimRcsFileName = "_novimrcs"
    else
        let g:rvSkipVimRcsFileName = ".novimrcs"
    endif
endif


" Set where the files are saved
"--------------------------------------------------------------------------
if !exists('g:rvSaveDirectoryType')
    let g:rvSaveDirectoryType = 0
endif


" Set the name of the directory to save RCS files to
"--------------------------------------------------------------------------
if !exists('g:rvSaveDirectoryName')
    if g:rvSaveDirectoryType == 0
        let g:rvSaveDirectoryName = "RCS"
    else
        let g:rvSaveDirectoryName = $VIM.g:rvDirSeparator."RCSFiles"
    endif
endif


" Hook Save RCS function to events
"--------------------------------------------------------------------------
augroup rcsvers
   au!
   let s:types = "*"
   exe "au BufWritePost,FileWritePost,FileAppendPost " . s:types . " call s:rcsvers_post()"
augroup END


" Generate suffix
"--------------------------------------------------------------------------
function! s:CreateSuffix()
    if g:rvSaveDirectoryType == 0
        return ",v"
    else
        return "," . expand("%:p:h:gs?\[:/ \\\\]?_?")
    endif
endfunction


" Write the RCS
"--------------------------------------------------------------------------
function! s:rcsvers_post()

    " Exclude directories from versioning, by putting skipfile there.
    if filereadable( expand("%:p:h") . g:rvDirSeparator . g:rvSkipVimRcsFileName )
        return
    endif

    let l:suffix = s:CreateSuffix()

    " Create RCS dir if it doesn't exist
    if !isdirectory(g:rvSaveDirectoryName)
        let l:returnval = system("mkdir " . g:rvSaveDirectoryName)
        if ( l:returnval != "" )
            let l:err = "Could not create rcs directory: " . g:rvSaveDirectoryName . "\nThe error was: " . l:returnval
            confirm(l:err, "&Okay")
            return
        endif
    endif

    " Generate name of RCS file
    let l:rcsfile = g:rvSaveDirectoryName . g:rvDirSeparator . expand("%:t") . l:suffix

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
    return system(l:cmd)

endfunction


" Display the revision log
"--------------------------------------------------------------------------
function! s:DisplayLog()
    let l:suffix = s:CreateSuffix()
    let l:rcsfile = g:rvSaveDirectoryName . g:rvDirSeparator . bufname("%") . l:suffix

    " Grep will find all lines with revision and date in rlog output
    let l:grepstr = "grep \"\\(^revision\\)\\|\\(^date\\)\""

    " Sed will take each revision line and date line and combine them
    " into one line stripping out the rest.
    let l:sedstr = "sed -e \"N;s/\\n//g;s/revision \\+\\([0-9.]\\+\\)[\t a-zA-Z:;]*date\\(:[^;]\\+\\).\\+/\\1\\2/g\" -"

    " Create the command
    let l:cmd = "rlog -x" . l:suffix . " " . bufname("%") . " " . l:rcsfile . " | " . l:grepstr . " | " . l:sedstr

    " This is the name of the buffer that holds the revision log list.
    let l:bufferName = "RevisionLog"

    " If a buffer with the name rlog exists, delete it.
    if bufexists(l:bufferName)
    execute 'bd! ' l:bufferName
    endif

    " Create a new buffer (vertical split).
    execute 'vnew ' l:bufferName
    execute 'vertical resize 35'

    " Map <enter> to compare current file to that version
    nnoremap <buffer> <CR> :call <SID>CompareFiles()<CR>

    " Execute the command.
    execute 'r!' l:cmd

    " Make is so that the file can't be edited.
    setlocal nomodified
    setlocal nomodifiable
    setlocal readonly

    " Go to about the beginning of the buffer.
    execute "normal 3G"
endfunction


" Function to compare the current file to the selected revision
"--------------------------------------------------------------------------
function! s:CompareFiles()

    " Get just the revision number
    let l:revision = substitute(getline("."), "^\\([.0-9]\\+\\).\\+", "\\1", "g")

    " Close the revision log, This will send us back to the original file.
    execute "bd!"

    let l:suffix = s:CreateSuffix()
    let l:rcsfile = g:rvSaveDirectoryName . g:rvDirSeparator . bufname("%") . l:suffix

    " Build command
    "
    " co options are as follows:
    " -q        Keep co quiet ( no messages )
    " -p        Print the revision rather than storing in a file.
    "             This allows us to capture it with the r! command.
    " -r        Revision number to check out.
    " -x        Suffix to use for rcs files.
    let l:cmd = "co -q -p -r" . l:revision . " -x" . l:suffix . " " . bufname("%") . " " . l:rcsfile

    " Create a new buffer to place the co output
    execute "new ". g:rvTempDir .g:rvDirSeparator. bufname("%")

    " Delete the contents if it's not empty
    execute "normal 1G"
    execute "normal dG"

    " Run the command and capture the output
    execute "silent r!" . l:cmd

    " Write the file and quit it
    execute "wq"

    " Execute the compare program.
    execute "!" . g:rvCompareProgram. " " g:rvTempDir. g:rvDirSeparator. bufname("%") . " " . bufname("%")

endfunction
