"------------------------------------------------------------------------------
" Name Of File: rcsvers.vim
"
"  Description: Vim plugin to automatically save backup versions in RCS
"               whenever a file is saved.
"
"       Author: Roger Pilkey (rpilkey at magma.ca)
"   Maintainer: Juan Frias (frias.junk at earthlink.net)
"
"  Last Change: $Date: 2003/03/10 10:07:13 $
"      Version: $Revision: 1.11 $
"
"    Copyright: Permission is hereby granted to use and distribute this code,
"               with or without modifications, provided that this header
"               is included with it.
"
"               This script is to be distributed freely in the hope that it
"               will be useful, but is provided 'as is' and without warranties
"               as to performance of merchantability or any other warranties
"               whether expressed or implied. Because of the various hardware
"               and software environments into which this script may be put,
"               no warranty of fitness for a particular purpose is offered.
"
"               GOOD DATA PROCESSING PROCEDURE DICTATES THAT ANY SCRIPT BE
"               THOROUGHLY TESTED WITH NON-CRITICAL DATA BEFORE RELYING ON IT.
"
"               THE USER MUST ASSUME THE ENTIRE RISK OF USING THE SCRIPT.
"
"               The author and maintainer do not retain any liability on any
"               damage caused through the use of this script.
"
"      Install: 1. Read the section titled 'Options'
"               2. Setup any variables need in your vimrc file
"               3. Copy 'rcsvers.vim' to your plugin directory.
"
"  Mapped Keys: <Leader>rlog    To access saved revisions log.
"
"               <enter>         This will compare the current file to the
"                               revision under the cursor (works only in
"                               the revision log window)
"
"------------------------------------------------------------------------------
" Please send me any bugs you find, so I can keep the script up to date.
"------------------------------------------------------------------------------
"
" Additional Information: {{{1
"------------------------------------------------------------------------------
" Vim plugin for automatically saving backup versions in rcs
" whenever a file is saved.
"
" What's RCS? See http://www.gnu.org/software/rcs/rcs.html
"
" Be careful if you really use RCS as your production file control, it
" will add versions like crazy. See options bellow for work around.
"
" If you're using Microsoft Windows, then the rcs programs are available by
" installing WinCVS (http://www.wincvs.org/), and putting the wincvs directory
" in your path.
"
" rcs-menu.vim by Jeff Lanzarotta is handy to have along with this (vimscript #41).
"
" History: {{{1
"------------------------------------------------------------------------------
"
" 1.11  Minor bug fix, when using spaces in the description. Also added some
"       error detection code to check and see that RCS and CI where
"       successful. And removed requirements for SED and GREP, script will no
"       longer need these to display the log.
"
" 1.10  Fixed some major bugs with files with long filenames and spaces
"       Win/Dos systems. Added a variable to pass additional options to the
"       initial RCS check in. Fixed some documentations typos.
"
" 1.9   Added even more options, the ability to set your own description and
"       pass additional options to CI command. Dos/Win Temp directory is taken
"       from the $TEMP environment variable, and quote file names when using
"       diff program to prevent errors with long filenames with spaces. Also
"       removed confirm box from script.
"
" 1.8   Fixed minor Prefix bug,
"
" 1.7   Will not alter the $xx$ tags when automatically checking in files.
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
" Options: {{{1
"------------------------------------------------------------------------------
"
" <Leader>rlog
"       This is the default key map to display the revision log. search
"       for 'key' to overwrite this key.
"
" g:rvCompareProgram
"       This is the program that will be called to compare two files,
"       the temporary file created by the revision log and the current
"       file. The default program is diff. To overwrite use:
"           let g:rvCompareProgram = <your compare program>
"       in your vimrc file. Win32 users you may want to use:
"           let g:rvCompareProgram = start <your program>
"       for an asynchronous run, type :help :!start for details.
"
" g:rvFileQuote
"       This is the character used to enclose filenames when calling the
"       compare program. By default in DOS/Win Systems is '"' (quote) in
"       all other system it's blank. To overwrite this use:
"           let g:rvFileQuote = <quote char>
"       in your vimrc file.
"
" g:rvDirSeparator
"       Separator to use between paths, the script will try to auto detect
"       this but to overwrite use:
"           let g:rvDirSeparator = <separator>
"       in your vimrc file.
"
" g:rvTempDir
"       This is the temporary directory to create an old revision file to
"       compare it to the current file. The default is $temp for Dos/win
"       systems and <g:rvDirSeparator>temp for all other systems. The
"       script will automatically append the directory separator to the
"       end, so do not include this. To overwrite defaults use:
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
"           2 = Save in current directory (same as the original file)
"
"       NoTE: If using g:rvSaveDirectoryType = 2 make sure you use
"             a suffix or the script might overwrite your file.
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
"           3 = use a unique suffix with a ',v' Appended to the end.
"           4 = User defined suffix.
"       If you select type number 4 the default is ',v' to overwrite Use:
"           let g:rvSaveSuffix = 'xxx'
"       where 'xxx' is your user defined suffix.
"
" g:rvCiOptions
"       This specifies additional options to send to CI (check in program)
"       by default this is blank. Refer to RCS documentation for additional
"       options to pass. To overwrite use:
"           let g:rvCiOptions = <options>
"       in your vimrc file.
"
" g:rvRcsOptions
"       This specifies additional options to send to RCS (program that
"       creates the initial RCS file) by default this is set to '-ko' to
"       prevent $xx$ tags from being altered. Refer to RCS documentation
"       for additional options to pass. To overwrite use:
"           let g:rvRcsOptions = <options>
"       in your vimrc file.
"
" g:rvDescription
"       This allows you to set your initial description and version
"       message. The default value is 'vim'. To overwrite use:
"           let g:rvDescription = <description>
"       in your vimrc file.
"
"

" Setup Global variables {{{1
"--------------------------------------------------------------------------

" Load script once
"--------------------------------------------------------------------------
if exists("loaded_rcsvers")
    finish
endif
let loaded_rcsvers = 1


" Set additional RCS options
"--------------------------------------------------------------------------
if !exists('g:rvRcsOptions')
    let g:rvRcsOptions = "-ko"
endif

" Set additional ci options
"--------------------------------------------------------------------------
if !exists('g:rvCiOptions')
    let g:rvCiOptions = ""
endif

" Set initial description and version message.
"--------------------------------------------------------------------------
if !exists('g:rvDescription')
    let g:rvDescription = "vim"
endif

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

" Set file name quoting
"--------------------------------------------------------------------------
if !exists('g:rvFileQuote')
    if has("win32") || has("win16") || has("dos32") || has("dos16") || has("os2")
        let g:rvFileQuote = '"'

    else " *nix systems
        let g:rvFileQuote = ""
    endif
endif

" Set the temp directory
"--------------------------------------------------------------------------
if !exists('g:rvTempDir')
    if has("win32") || has("win16") || has("dos32") || has("dos16") || has("os2")
        let g:rvTempDir = expand("$temp")
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
        let g:rvSaveDirectoryName = strpart(expand("%:p"), 0, strridx(expand("%:p"), g:rvDirSeparator) + 1)."RCS"

    elseif g:rvSaveDirectoryType == 1
        let g:rvSaveDirectoryName = $VIM.g:rvDirSeparator."RCSFiles"

    else " Type 2
        let g:rvSaveDirectoryName = strpart(expand("%:p"), 0, strridx(expand("%:p"), g:rvDirSeparator))

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
   exe "au BufWritePost,FileWritePost,FileAppendPost ".s:types." call s:rcsvers_post()"
augroup END


" Generate suffix
"--------------------------------------------------------------------------
function! s:CreateSuffix()
    if g:rvSaveSuffixType == 0
        return ""

    elseif g:rvSaveSuffixType == 1
        return ",v"

    elseif g:rvSaveSuffixType == 2
        return ",".expand("%:p:h:gs?\[:/ \\\\]?_?")

    elseif g:rvSaveSuffixType == 3
        return ",".expand("%:p:h:gs?\[:/ \\\\]?_?").",v"

    else " type 4 User defined
        return g:rvSaveSuffix

    endif
endfunction


" Function: Write the RCS {{{1
"--------------------------------------------------------------------------
function! s:rcsvers_post()

    " Exclude directories from versioning, by putting skip file there.
    if filereadable( expand("%:p:h").g:rvDirSeparator.g:rvSkipVimRcsFileName )
        return
    endif

    let l:suffix = s:CreateSuffix()

    " Create RCS dir if it doesn't exist
    if (g:rvSaveDirectoryType != 2) && (!isdirectory(g:rvSaveDirectoryName))
        let l:returnval = system("mkdir ".g:rvSaveDirectoryName)
        if ( l:returnval != "" )
            let l:err = "Could not create rcs directory: ".g:rvSaveDirectoryName
            let l:err = l:err."\nThe error was: ".l:returnval
            echo l:err
            return
        endif
    endif

    " Generate name of RCS file
    let l:rcsfile = g:rvSaveDirectoryName.g:rvDirSeparator.expand("%:t").l:suffix

    " ci options are as follows:
    " -i        Initial check in
    " -l        Check out and lock file after check in.
    " -t-       File description at initial check in.
    " -x        Suffix to use for rcs files.
    " -m        Log message

    if (getfsize(l:rcsfile) == -1)
        " Initial check-in, create an empty RCS file
        let l:cmd = "rcs -i -t-\"".g:rvDescription."\" ".g:rvRcsOptions

        if (g:rvSaveSuffixType != 0)
            let l:cmd = l:cmd." -x".l:suffix
        endif

        let l:cmd = l:cmd." ".g:rvFileQuote.l:rcsfile.g:rvFileQuote
        let l:output = system(l:cmd)
        if ( v:shell_error == -1 )
            echo "Command could not be executed."
        elseif ( v:shell_error != 0 )
            echo "Error executing command."
            echo l:cmd
            echo l:output
        endif
    endif

    let l:cmd = "ci -l -m\"".g:rvDescription."\" ".g:rvCiOptions

    if (g:rvSaveSuffixType != 0)
        let l:cmd = l:cmd." -x".l:suffix
    endif

    " Build command string <command> <filename> <rcs file>
    let l:cmd = l:cmd." ".g:rvFileQuote.bufname("%").g:rvFileQuote

    if (g:rvSaveSuffixType != 0)
        let l:cmd = l:cmd." ".g:rvFileQuote.l:rcsfile.g:rvFileQuote
    endif

    let l:output = system(l:cmd)
    if ( v:shell_error == -1 )
        echo "Command could not be executed."
    elseif ( v:shell_error != 0 )
        echo "Error executing command."
        echo l:cmd
        echo l:output
    endif

endfunction


" Function: Display the revision log {{{1
"--------------------------------------------------------------------------
function! s:DisplayLog()
    let l:suffix = s:CreateSuffix()
    let l:rcsfile = g:rvSaveDirectoryName.g:rvDirSeparator.bufname("%").l:suffix

    " Create the command
    let l:cmd = "rlog"

    if (g:rvSaveSuffixType != 0)
        let l:cmd = l:cmd." -x".l:suffix
    endif
    let l:cmd = l:cmd." ".g:rvFileQuote.bufname("%").g:rvFileQuote." "
    let l:cmd = l:cmd.g:rvFileQuote.l:rcsfile.g:rvFileQuote

    " This is the name of the buffer that holds the revision log list.
    let l:bufferName = "RevisionLog"

    " If a buffer with the name rlog exists, delete it.
    if bufexists(l:bufferName)
    sil! exe 'bd! ' l:bufferName
    endif

    " Create a new buffer (vertical split).
    sil! exe 'vnew ' l:bufferName
    sil! exe 'vertical resize 35'

    " Map <enter> to compare current file to that version
    nnoremap <buffer> <CR> :call <SID>CompareFiles()<CR>

    " Execute the command.
    sil! exe 'r!' l:cmd

    " Remove any line not matching 'date' or 'revision'
    let l:lines = line("$")
    while l:lines
        if getline(l:lines) !~ "^\\(date\\|revision\\).*"
            exe l:lines.",".l:lines."d"
        endif
        let l:lines = l:lines - 1
    endwhile

    " Format date and revision into a single line.
    let l:lines = line("$")
    let l:curr_line = 1
    while l:curr_line < (l:lines / 2) + 1

        " Join the revison to the date...
        normal J

        " and format as: 'revision: date time'
        let l:text = getline(".")
        let l:text = substitute(l:text,
            \ "revision\\s\\+\\([0-9.]\\+\\).*date\\(:[^;]\\+\\).\\+",
            \ "\\1\\2", "g")

        " Delete the current line, insert ours, and move to the next one.
        exe "normal ddO".l:text."\<esc>"
        normal j

        let l:curr_line = l:curr_line + 1
    endwhile

    " Make is so that the file can't be edited.
    setlocal nomodified
    setlocal nomodifiable
    setlocal readonly

    " Go to about the beginning of the buffer.
    sil! exe "normal 2G"
endfunction


" Function: Compare the current file to the selected revision {{{1
"--------------------------------------------------------------------------
function! s:CompareFiles()

    " Get just the revision number
    let l:revision = substitute(getline("."), "^\\([.0-9]\\+\\).\\+", "\\1", "g")

    " Close the revision log, This will send us back to the original file.
    sil! exe "bd!"

    let l:suffix = s:CreateSuffix()
    let l:rcsfile = g:rvSaveDirectoryName.g:rvDirSeparator.bufname("%").l:suffix

    " Build command
    "
    " co options are as follows:
    " -q        Keep co quiet ( no messages )
    " -p        Print the revision rather than storing in a file.
    "             This allows us to capture it with the r! command.
    " -r        Revision number to check out.
    " -x        Suffix to use for rcs files.

    let l:cmd = "co -q -p -r".l:revision

    if (g:rvSaveSuffixType != 0)
        let l:cmd = l:cmd." -x".l:suffix
    endif

    let l:cmd = l:cmd." ".g:rvFileQuote.bufname("%").g:rvFileQuote." ".g:rvFileQuote.l:rcsfile.g:rvFileQuote

    " Create a new buffer to place the co output
    let l:tmpfile = g:rvTempDir.g:rvDirSeparator."_".bufname("%")
    sil! exe "new ".l:tmpfile

    " Delete the contents if it's not empty
    sil! exe "1,$d"

    " Run the command and capture the output
    sil! exe "silent r!".l:cmd

    " Write the file and quit it
    sil! exe "w!"
    sil! exe "bd!"

    " Execute the compare program.
    sil exe "!".g:rvCompareProgram." " g:rvFileQuote.l:tmpfile.g:rvFileQuote.' '.g:rvFileQuote.bufname("%").g:rvFileQuote

endfunction

"}}}1

" Default key mapping to generate revision log.
"--------------------------------------------------------------------------
nnoremap <Leader>rlog :call <SID>DisplayLog()<cr>

" vim600: set foldmethod=marker :
