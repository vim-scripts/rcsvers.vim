"    Copyright: Permission is hereby granted to use and distribute this code,
"               with or without modifications, provided that this copyright
"               notice is copied with it. Like anything else that's free,
"               this script is provided *as is* and comes with no
"               warranty of any kind, either expressed or implied. In no
"               event will the author(s) be liable for any damamges
"               resulting from the use of this script.
"
" Name Of File: rcsvers.vim
"  Description: Vim plugin to automatically save backup versions in RCS
"       Author: Roger Pilkey (rpilkey at magma.ca)
"   Maintainer: Juan Frias (frias.junk at earthlink.net)
"  Last Change: $Date: 2003/02/27 17:55:29 $
"      Version: $Revision: 1.7 $
"
"        Usage: Normally, this file should reside in the plugins directory.
"
"--------------------------------------------------------------------------
"
" Please send me any bugs so I can keep the script up to date.
"
"--------------------------------------------------------------------------
"
" Vim plugin for automatically saving backup versions in rcs
" whenever a file is saved.
"
" What's RCS? See http://www.gnu.org/software/rcs/rcs.html
"
" Be careful if you really use RCS as your production file control, it
" will add versions like crazy. See options bellow for work arounds.
"
" If you're using Microsoft Windows, then the rcs programs are available by
" installing WinCVS (http://www.wincvs.org/), and putting the wincvs directory
" in your path.
"
" rcs-menu.vim by Jeff Lanzarotta is handy to have along with this (vimscript #41).
"
" 1.7   Will not alter the $xx$ tags when automaticaly checking in files.
"       (Thanks to Engelbert Gruber). Added option to save under the current
"       directory with no RCS sub directory. Also added the option to choose
"       your own suffixes.
"
" 1.6   Complete script re-write. added ability to set user options by vimrc
"       and will now allow you to compare to older revision if you have grep
"       and sed installed.
"
" 1.5   add l:skipfilename to allow exclusion of directories from versioning.
"       and FIX for editing in current directory with local RCS directory.
"
" 1.4   FIX editing files not in current directory.
"
" 1.3   option to select the rcs directory,
"       and better comments thanks to Juan Frias
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
"       they will be saved under the current directory (under RCS). To
"       overwrite use:
"           let g:rvSaveDirectoryType = 1
"       in your vimrc file, options are as follows:
"           0 = Save in current directory (under RCS)
"           1 = Single directory for all files
"           2 = Save in current direcotry (same as the orignal file)
"
"       NoTE: If using g:rvSaveDirectoryType = 2 make sure you use
"             suffix or the script might overwrite your file.
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
" g:rvSaveSuffixType
"       This specifies what the script uses as a suffix, when saving the
"       RCS files. The default is ',v' suffix when using rvSaveDirectoryType
"       number 0 (current directory under RCS), and unique suffix when using
"       rvSaveDirectoryType number 1. (single directory for all files). To
"       overwrite the defaults use:
"           let g:rvSaveSuffixType = x
"       where 'x' is one of the following
"           0 = No suffix.
"           1 = Use the ',v" suffix
"           2 = Use a unique suffix (take the full path and changes the
"               directory separators to underscores)
"           3 = use a unique suffix with a 'v' Appended to the end.
"           4 = User defined suffix.
"       If you select type number 3 the default is ',v' to overwrite Use:
"           let g:rvSaveSuffix = 'xxx'
"       where 'xxx' is your user defined suffix.
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

    elseif g:rvSaveDirectoryType == 1
        let g:rvSaveDirectoryName = $VIM.g:rvDirSeparator."RCSFiles"

    else " Type 2
        let g:rvSaveDirectoryName = "."

    endif
endif

" Set the suffix type
"--------------------------------------------------------------------------
if !exists('g:rvSaveSuffixType')
    if g:rvSaveDirectoryType == 0
        let g:rvSaveSuffixType = 1
    else
        let g:rvSaveSuffixType = 2
    endif
endif

" Set default user defined suffix
"--------------------------------------------------------------------------
if (g:rvSaveSuffixType == 4) && (!exists('g:rvSaveSuffix'))
    let g:rvSaveSuffix = ",v"
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
    if g:rvSaveSuffixType == 0
        return ""

    elseif g:rvSaveSuffixType == 1
        return ",v"

    elseif g:rvSaveSuffixType == 2
        return "," . expand("%:p:h:gs?\[:/ \\\\]?_?")

    elseif g:rvSaveSuffixType == 3
        return "," . expand("%:p:h:gs?\[:/ \\\\]?_?") . ",v"

    else " type 4 User defined
        return g:rvSaveSuffix

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
    if (g:rvSaveDirectoryType != 2) && (!isdirectory(g:rvSaveDirectoryName))
        let l:returnval = system("mkdir " . g:rvSaveDirectoryName)
        if ( l:returnval != "" )
            let l:err = "Could not create rcs directory: " . g:rvSaveDirectoryName
            let l:err = l:err . "\nThe error was: " . l:returnval
            echo l:err
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
    " -ko       Used for RCS to not modify $xx$ tags

    if (getfsize(l:rcsfile) == -1)
        " Initial check-in, create an empty RCS file
        let l:cmd = "rcs -i -ko -t-vim " .l:rcsfile
        let l:xx = system(l:cmd)
    endif

    let l:cmd = "ci -l -mvim -t-vim"

    if (g:rvSaveSuffixType != 0)
        let l:cmd = l:cmd . " -x" . l:suffix
    endif

    " Build command string <command> <filename> <rcs file>
    let l:cmd = l:cmd . " " . bufname("%")

    if (g:rvSaveSuffixType != 0)
        let l:cmd = l:cmd . " " . l:rcsfile
    endif

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
