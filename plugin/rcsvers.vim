"------------------------------------------------------------------------------
" Name Of File: rcsvers.vim
"
"  Description: Vim plugin to automatically save backup versions in RCS
"               whenever a file is saved.
"
"       Author: Roger Pilkey (rpilkey at magma.ca)
"   Maintainer: Juan Frias (frias.junk at earthlink.net)
"
"  Last Change: $Date: 2003/12/09 14:18:35 $
"      Version: $Revision: 1.16 $
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
"      Install: 1. Read the section titled 'User Options'
"               2. Setup any variables you need in your vimrc file
"               3. Copy 'rcsvers.vim' to your plugin directory.
"
"  Mapped Keys: <Leader>rlog    To access saved revisions log.  This works as
"                               toggle to quit the revision windows too.
"
"               <enter>         This will compare the current file to the
"                               revision under the cursor (works only in
"                               the revision log window)
"
"               <Leader>older   does a diff with the previous version
"
"               <Leader>newer   does a diff with the next version
"
" You probably want to map these to something easier to type, like a function
" key
"
"------------------------------------------------------------------------------
" Please send me any bugs you find, so I can keep the script up to date.
"------------------------------------------------------------------------------
"
" Additional Information: {{{1
"------------------------------------------------------------------------------
" Vim plugin for automatically saving backup versions in rcs whenever a file
" is saved.
"
" What's RCS? See http://www.gnu.org/software/rcs/rcs.html
"
" Be careful if you really use RCS as your production file control, it will
" add versions like crazy. See options below for work arounds.
"
" If you're using Microsoft Windows, then the rcs programs are available by
" installing WinCVS (http://www.wincvs.org), and putting the wincvs directory
" in your path. (WinCVS 1.2 or earlier only, they took out the programs as of
" 1.3)
"
" rcs-menu.vim by Jeff Lanzarotta is handy to have along with this
" (vimscript #41).
"
" History: {{{1
"------------------------------------------------------------------------------
"
" 1.16  Save some settings that "set diff" mangles, and different check for
"       &cp
"
" 1.15  Add functions to go back and forth between versions (mapped to \older
"       and \newer). It's kind of jerky, but comes in handy sometimes. Also
"       fixed a few bugs with quotes.
"
" 1.14  Add option to set 'rlog' command-line options.  fix rlog display,
"       which would crash once in a while saying stuff like "10,10d invalid
"       range". When creating a new RCS file on an existing text file, save a
"       version before adding the new revision.
"
" 1.13  A g:rvFileQuote fix, suggested by Wiktor Niesiobedzki.  Add the
"       ability to use the current instance of vim for the diff, which is now
"       the default.  Change the name of the diff temp file to include the
"       version.  Make \rlog a toggle (on/off)
"
" 1.12  Script will not load if the 'cp' flag is set. Added the option to
"       use an exclude expression, and include expression. Fixed yet more bugs
"       thanks to Roger for all the beta testing.
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
" User Options: {{{1
"------------------------------------------------------------------------------
"
" <Leader>rlog
"       This is the default key map to display the revision log. search
"       for 'key' to override this key.
"
" <Leader>older
"       This is the default key map to display the previous revision. search
"       for 'key' to override this key.
"
" <Leader>newer
"       This is the default key map to display the next revision. search
"       for 'key' to override this key.
"
" g:rvCompareProgram
"       This is the program that will be called to compare two files,
"       the temporary file created by the revision log and the current
"       file. The default program is vimdiff in the current instance of vim.
"       To override use:
"           let g:rvCompareProgram = <your compare program>
"       in your vimrc file. Win32 users you may want to use:
"           let g:rvCompareProgram = start <your program>
"       for an asynchronous run, type :help :!start for details.
"       example:
"           let g:rvCompareProgram = 'start\ C:\\Vim\\vim61\\gvim.exe\ -d\ -R\ --noplugin\ '
"
"       To open the diff within the current instance of vim, use 'This'
"       (default)
"
" g:rvFileQuote
"       This is the character used to enclose filenames when calling the
"       compare program. By default it is '"' (double-quote).
"       To override this use:
"           let g:rvFileQuote = <quote char>
"       in your vimrc file.
"
" g:rvDirSeparator
"       Separator to use between paths, the script will try to auto detect
"       this but to override use:
"           let g:rvDirSeparator = <separator>
"       in your vimrc file.
"
" g:rvTempDir
"       This is the temporary directory to create an old revision file to
"       compare it to the current file. The default is $temp for Dos/win
"       systems and <g:rvDirSeparator>temp for all other systems. The
"       script will automatically append the directory separator to the
"       end, so do not include this. To override defaults use:
"           let g:rvTempDir = <your directory>
"       in your vimrc file.
"
" g:rvSkipVimRcsFileName
"       This is the name of the file the script will look for, if it's found
"       in the directory the file is being edited the RCS file will not
"       be written. By default the name is _novimrcs for Dos/win systems
"       and .novimrcs for all other. To override use:
"           let  g:rvSkipVimRcsFileName = <filename>
"       in your vimrc file.
"
" g:rvSaveDirectoryType
"       This specifies how the script will save the RCS files. By default
"       they will be saved under the current directory (under RCS). To
"       override use:
"           let g:rvSaveDirectoryType = 1
"       in your vimrc file, options are as follows:
"           0 = Save in current directory (under RCS)
"           1 = Single directory for all files
"           2 = Save in current directory (same as the original file)
"
"       Note: If using g:rvSaveDirectoryType = 2 make sure you use
"             a suffix or the script might overwrite your file.
"
" g:rvSaveDirectoryName
"       This specifies the name of the directory where the RCS files will
"       be saved. By default if g:rvSaveDirectoryType = 0 (saving to
"       the current directory) the script will use RCS. If
"       g:rvSaveDirectoryType = 1 (saving all files in a single
"       directory) the script will save them to $VIM/RCSFiles. To override
"       the default name use:
"           let g:rvSaveDirectoryName = <my directory name>
"       in your vimrc file.
"
" g:rvSaveSuffixType
"       This specifies what the script uses as a suffix, when saving the
"       RCS files. The default is ',v' suffix when using rvSaveDirectoryType
"       number 0 (current directory under RCS), and unique suffix when using
"       rvSaveDirectoryType number 1. (single directory for all files). To
"       override the defaults use:
"           let g:rvSaveSuffixType = x
"       where 'x' is one of the following
"           0 = No suffix.
"           1 = Use the ',v' suffix
"           2 = Use a unique suffix (take the full path and changes the
"               directory separators to underscores)
"           3 = use a unique suffix with a ',v' Appended to the end.
"           4 = User defined suffix.
"       If you select type number 4 the default is ',v'. To override use:
"           let g:rvSaveSuffix = 'xxx'
"       where 'xxx' is your user defined suffix.
"
" g:rvCiOptions
"       This specifies additional options to send to CI (check in program)
"       by default this is blank. Refer to RCS documentation for additional
"       options to pass. To override use:
"           let g:rvCiOptions = <options>
"       in your vimrc file.
"
" g:rvRcsOptions
"       This specifies additional options to send to RCS (program that
"       creates the initial RCS file) by default this is set to '-ko' to
"       prevent $xx$ tags from being altered. Refer to RCS documentation
"       for additional options to pass. To override use:
"           let g:rvRcsOptions = <options>
"       in your vimrc file.
"
" g:rvRlogOptions
"       This specifies additional options to send to rlog (history displaying
"       program). By default this is set to '' to avoid surprising you.
"       Refer to RCS documentation for additional options to pass.
"       To override use:
"           let g:rvRlogOptions = <options>
"       in your vimrc file.
"       e.g.
"           " show the log using the local timezone
"           let g:rvRlogOptions = '-zLT'
"
" g:rvDescription
"       This allows you to set your initial description and version
"       message. The default value is 'vim'. To override use:
"           let g:rvDescription = <description>
"       in your vimrc file.
"
" g:rvExcludeExpression
"       This expression is evaluated with the function 'match'. The script
"       tests the expression against the full file name and path of the file
"       being saved. If the expression is found in the file name then the
"       script will NOT create an RCS file for it. The default is an empty
"       string, in which case no checking is done. To override use:
"           let g:rvExcludeExpression = <your expression>
"       in your vimrc file.
"
"       Example: The expression below will exclude files containing .usr and
"       .tmp in their file names. The '\c' is used to ignore case. Note that
"       this is evaluated against the full file name and path so if you have
"       the file '/home/joe/.tmp/hi.txt' the script will not generate an RCS
"       file since '.tmp' is found in the path.
"
"           let g:rvExcludeExpression = '\c\.usr\|\c\.tmp'
"
"       Type ':help match' for help on how to setup an expression. In this
"       script {exp} will be the file name and path, and {pat} will be the
"       expression you provide.
"
" g:rvIncludeExpression
"       This expression is evaluated with the function 'match'. The script
"       tests the expression against the full file name and path of the file
"       being saved. If the expression is found in the file name, then the
"       script will create an RCS file for it, but if it's not found it will
"       NOT. The default is an empty string, in which case no checking is done
"       and all files will generate an RCS file except if an exclude
"       expression is present, see g:rvExcludeExpression for a sample
"       expression.
"

" Global variables: {{{1
"------------------------------------------------------------------------------

" Load script once
"------------------------------------------------------------------------------
if exists("loaded_rcsvers")
    finish
endif
let loaded_rcsvers = 1

let s:save_cpo = &cpo
set cpo&vim

" Set additional RCS options
"------------------------------------------------------------------------------
if !exists('g:rvRcsOptions')
    let g:rvRcsOptions = "-ko"
endif

" Set additional ci options
"------------------------------------------------------------------------------
if !exists('g:rvCiOptions')
    let g:rvCiOptions = ""
endif

" Set additional rlog options
"------------------------------------------------------------------------------
if !exists('g:rvRlogOptions')
    let g:rvRlogOptions = ""
endif

" Set initial description and version message.
"------------------------------------------------------------------------------
if !exists('g:rvDescription')
    let g:rvDescription = "vim"
endif

" Set the compare program
"------------------------------------------------------------------------------
if !exists('g:rvCompareProgram')
    let g:rvCompareProgram = "This"
endif

" Set the directory separator
"------------------------------------------------------------------------------
if !exists('g:rvDirSeparator')
    if has("win32") || has("win16") || has("dos32")
                \ || has("dos16") || has("os2")
        let g:rvDirSeparator = "\\"

    elseif has("mac")
        let g:rvDirSeparator = ":"

    else " *nix systems
        let g:rvDirSeparator = "\/"
    endif
endif

" Set file name quoting
"------------------------------------------------------------------------------
if !exists('g:rvFileQuote')
    let g:rvFileQuote = '"'
endif

" Set the temp directory
"------------------------------------------------------------------------------
if !exists('g:rvTempDir')
    if has("win32") || has("win16") || has("dos32")
                \ || has("dos16") || has("os2")
        let g:rvTempDir = expand("$temp")
    else
        let g:rvTempDir = g:rvDirSeparator."tmp"
    endif
endif

" Skip vim's rcs file name
"------------------------------------------------------------------------------
if !exists('g:rvSkipVimRcsFileName')
    if has("win32") || has("win16") || has("dos32")
                \ || has("dos16") || has("os2")
        let g:rvSkipVimRcsFileName = "_novimrcs"
    else
        let g:rvSkipVimRcsFileName = ".novimrcs"
    endif
endif

" Set where the files are saved
"------------------------------------------------------------------------------
if !exists('g:rvSaveDirectoryType')
    let g:rvSaveDirectoryType = 0
endif

" Set the suffix type
"------------------------------------------------------------------------------
if !exists('g:rvSaveSuffixType')
    if g:rvSaveDirectoryType == 0
        let g:rvSaveSuffixType = 1
    else
        let g:rvSaveSuffixType = 2
    endif
endif

" Set default user defined suffix
"------------------------------------------------------------------------------
if (g:rvSaveSuffixType == 4) && (!exists('g:rvSaveSuffix'))
    let g:rvSaveSuffix = ",v"
endif

" Set the default Exclude expression
"------------------------------------------------------------------------------
if !exists('g:rvExcludeExpression')
    let g:rvExcludeExpression = ""
endif

" Set the default Include expression
"------------------------------------------------------------------------------
if !exists('g:rvIncludeExpression')
    let g:rvIncludeExpression = ""
endif

" Hook the RCS function to the Save events {{{1
"------------------------------------------------------------------------------
augroup rcsvers
   au!
   let s:types = "*"
   exe "au BufWritePost,FileWritePost,FileAppendPost ".
               \ s:types." call s:rcsvers(\"post\")"
   exe "au BufWritePre,FileWritePre,FileAppendPre ".
               \ s:types." call s:rcsvers(\"pre\")"
augroup END

augroup rcsvers
   au BufUnload * call s:bufunload()
augroup END

" Function: Autocommand for buffer unload to clean up after ourselves {{{1
"------------------------------------------------------------------------------
function! s:bufunload()
    "turn off the diff settings in the original file when you kill the child
    "buffer
    if exists("s:child_bufnr") && s:child_bufnr ==  expand("<abuf>")
        sil! exec bufwinnr(s:parent_bufnr) . " wincmd w"
        set nodiff

        if s:save_scrollbind == 0
            silent exec ":set noscrollbind"
        else
            silent exec ":set scrollbind" 
        endif
        silent exec ":set scrollopt=" . s:save_scrollopt
        if s:save_wrap == 0
            silent exec ":set nowrap"
        else
            silent exec ":set wrap"
        endif
        silent exec ":set foldmethod=" . s:save_foldmethod
        silent exec ":set foldcolumn=" . s:save_foldcolumn
        unlet! s:child_bufnr s:parent_bufnr s:revision
    endif
endfunction

" Function: save settings that get mangled {{{1
"------------------------------------------------------------------------------
function! s:RcsVersSaveSettings()
    if (!exists("s:child_bufnr"))
        "save some options that "set diff" mucks with
        let s:save_scrollbind=&scrollbind
        let s:save_scrollopt=&scrollopt
        let s:save_wrap=&wrap
        let s:save_foldmethod=&foldmethod
        let s:save_foldcolumn=&foldcolumn
    endif
endfunction

" Function: Set the name of the directory to save RCS files to {{{1
"------------------------------------------------------------------------------
function! s:GetSaveDirectoryName()

    if !exists('g:rvSaveDirectoryName')
        if g:rvSaveDirectoryType == 0
            let l:SaveDirectoryName = expand("%:p:h").g:rvDirSeparator."RCS".g:rvDirSeparator

        elseif g:rvSaveDirectoryType == 1
            let l:SaveDirectoryName = $VIM.g:rvDirSeparator."RCSFiles".g:rvDirSeparator

        else " Type 2
            let l:SaveDirectoryName = expand("%:p:h").g:rvDirSeparator
        endif
    else
        return g:rvSaveDirectoryName
    endif

    return l:SaveDirectoryName
endfunction

" Function: Generate suffix {{{1
"------------------------------------------------------------------------------
function! s:CreateSuffix()
    if g:rvSaveSuffixType == 0
        return ""

    elseif g:rvSaveSuffixType == 1
        "1 = Use the ',v" suffix
        return ",v"

    elseif g:rvSaveSuffixType == 2
        "2 = Use a unique suffix
        return ",".expand("%:p:h:gs?\[:/ \\\\]?_?")

    elseif g:rvSaveSuffixType == 3
        "3 = use a unique suffix with a ',v' Appended to the end.
        return ",".expand("%:p:h:gs?\[:/ \\\\]?_?").",v"

    elseif g:rvSaveSuffixType == 4
		"4 = User defined
        return g:rvSaveSuffix
	else
        echo "(rcsvers.vim) Error: unknown suffix type: ".g:rvSaveSuffixType
    endif
endfunction

" Function: Write the RCS {{{1
"------------------------------------------------------------------------------
function! s:rcsvers(type)

    " If this is a new file that hasn't been saved then we
    " can't create a previous entry so just exit.
    if a:type == "pre" && !filereadable(expand("%:p")) && !exists("modified")
        return
    endif

    " Exclude directories from versioning, by putting skip file there.
    if filereadable( expand("%:p:h").g:rvDirSeparator.g:rvSkipVimRcsFileName )
        return
    endif

    " Exclude file from versioning if matches exclude expression.
    if 0 != strlen(g:rvExcludeExpression) &&
            \ -1 != match(expand("%:p"), g:rvExcludeExpression)
        return
    endif

    " Include file for versioning if matches include expression.
    if 0 != strlen(g:rvIncludeExpression) &&
            \ -1 == match(expand("%:p"), g:rvIncludeExpression)
        return
    endif

    let l:suffix = s:CreateSuffix()

    let l:SaveDirectoryName = s:GetSaveDirectoryName()

    " Create RCS dir if it doesn't exist
    if (g:rvSaveDirectoryType != 2) && (!isdirectory(l:SaveDirectoryName))
        let l:returnval = system("mkdir ".g:rvFileQuote.l:SaveDirectoryName.g:rvFileQuote)
        if ( l:returnval != "" )
            let l:err = "(rcsvers.vim) Error creating rcs directory: ".l:SaveDirectoryName
            let l:err = l:err."\nThe error was: ".l:returnval
            echo l:err
            return
        endif
    endif

    " Generate name of RCS file
    let l:rcsfile = s:GetSaveDirectoryName().expand("%:p:t").l:suffix

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
            echo "(rcsvers.vim) Command could not be executed."
        elseif ( v:shell_error != 0 )
            echo "(rcsvers.vim) *** Error executing command."
            echo "Command was:"
            echo "--- beg --"
            echo l:cmd
            echo "--- end --"
            echo "Output:"
            echo "--- beg --"
            echo l:output
            echo "--- end --"
        endif
    else
        " We only need to do a pre-save if the RCS file
        " does not exist.
        if a:type == "pre"
            return
        endif
    endif

    let l:cmd = "ci -l -m\"".g:rvDescription."\" ".g:rvCiOptions

    if (g:rvSaveSuffixType != 0)
        let l:cmd = l:cmd." -x".l:suffix
    endif

    " Build the command string <command> <filename> <rcs file>
    let l:cmd = l:cmd." ".g:rvFileQuote.bufname("%").g:rvFileQuote

    if (g:rvSaveSuffixType != 0)
        let l:cmd = l:cmd." ".g:rvFileQuote.l:rcsfile.g:rvFileQuote
    endif

    let l:output = system(l:cmd)
    if ( v:shell_error == -1 )
        echo "(rcsvers.vim) Command could not be executed."
    elseif ( v:shell_error != 0 )
        echo "(rcsvers.vim) *** Error executing command."
        echo "Command was:"
        echo "--- beg --"
        echo l:cmd
        echo "--- end --"
        echo "Output:"
        echo "--- beg --"
        echo l:output
        echo "--- end --"
    endif

endfunction

" Function: Display the revision log {{{1
"------------------------------------------------------------------------------
function! s:DisplayLog()
    call s:RcsVersSaveSettings()
    "if the log or a version diff is already displayed, delete it and quit
    "(so that this function will work as a toggle)
    if (exists("s:child_bufnr"))
         silent exec "bd! " . s:child_bufnr
         return
    endif
    let l:suffix = s:CreateSuffix()

    "save the current directory, in case they automatically change dir when opening files
    let l:savedir = expand("%:p:h")

    let l:rcsfile = s:GetSaveDirectoryName().expand("%:p:t").l:suffix

    " Check for an RCS file
    if (getfsize(l:rcsfile) == -1)
        echo "(rcsvers.vim) Error: No RCS file found! (".l:rcsfile.")"
        return
    endif

    " Create the command
    let l:cmd = "rlog ".g:rvRlogOptions

    if (g:rvSaveSuffixType != 0)
        let l:cmd = l:cmd." -x".l:suffix
    endif
    let l:cmd = l:cmd." ".g:rvFileQuote.bufname("%").g:rvFileQuote." "
    let l:cmd = l:cmd.g:rvFileQuote.l:rcsfile.g:rvFileQuote

    " This is the name of the buffer that holds the revision log list.
    let l:bufferName = g:rvTempDir.g:rvDirSeparator."RevisionLog"

    " If a buffer with the name RevisionLog exists, delete it.
    if bufexists("l:bufferName")
    silent exe 'bd! "'.l:bufferName.'"'
    endif

    " Create a new buffer (vertical split).
    sil exe 'vnew ' l:bufferName
    sil exe 'vertical resize 35'
    let s:child_bufnr =  bufnr("%")

    " Map <enter> to compare current file to that version
    nnoremap <buffer> <CR> :call <SID>RlogCompareFiles()<CR>

    "change dir to the original file dir, in case they auto change dir
    "when opening files
    sil exec "cd ".g:rvFileQuote. l:savedir.g:rvFileQuote

    " Execute the command.
    sil exe 'r!' l:cmd

    let l:lines = line("$")

    " If there is less than 10 lines then there was
    " probably an error.
    if l:lines > 10

        " Remove any line not matching 'date' or 'revision'
        sil exe ":g!/^revision\\|^date/d"
        sil exe "normal 1G"
        " Format date and revision into a single line.
        let l:lines = line("$")
        let l:curr_line = 0

        while l:curr_line <= l:lines
            " Join the revision to the date...
            normal Jj
            let l:curr_line = l:curr_line + 2
        endwhile

        " and format as: 'revision: date time'
        sil! exe ":%s/revision\\s\\+\\([0-9.]\\+\\).\*".
                    \"date\\(:[^;]\\+\\).\\+/\\1\\2/g"

        " Go to about the beginning of the buffer.
        sil! exe "normal 1Gj"

    endif

    " Make it so that the file can't be edited.
    setlocal nomodified
    setlocal noswapfile
    setlocal nomodifiable
    setlocal readonly

endfunction

" Function: Compare the current file to the selected revision from rlog {{{1
"------------------------------------------------------------------------------
function! s:RlogCompareFiles()

    " Get just the revision number
    let l:revision = substitute(getline("."),
                \"^\\([.0-9]\\+\\).\\+", "\\1", "g")

    " Close the revision log, This will send us back to the original file.
    silent exe "bd!"

    call s:CompareFiles(l:revision)

endfunction

" Function: Compare the current file to the next revision ("older" or "newer") {{{1
"------------------------------------------------------------------------------
function! s:NextCompareFiles(direction)
    call s:RcsVersSaveSettings()

    "start off in the parent window
    if (exists("s:parent_bufnr"))
        sil exec bufwinnr(s:parent_bufnr) . "wincmd w"
    endif

    if (!exists("s:revision"))
        "no revision available, get the number of the head
        " Create the command
        let l:cmd = "rlog -r. ".g:rvRlogOptions

        let l:suffix = s:CreateSuffix()

        let l:rcsfile = s:GetSaveDirectoryName().expand("%:p:t").l:suffix

        if (g:rvSaveSuffixType != 0)
            let l:cmd = l:cmd." -x".l:suffix
        endif
        let l:cmd = l:cmd." ".g:rvFileQuote.bufname("%").g:rvFileQuote." "
        let l:cmd = l:cmd.g:rvFileQuote.l:rcsfile.g:rvFileQuote

        " Execute the command.
        let s:revision = system(l:cmd)

        "get the 'head:' line
        let s:revision = matchstr(s:revision,'head.\{-}\n')
        "get rid of the 'head:'
        let s:revision = substitute(s:revision,'^head: ',"","")
    endif

    "if the version is x.y , the head is x. and the tail is y
    let l:head = matchstr(s:revision,'^.*\.')
    let l:tail = matchstr(s:revision,'\d*.$')

    "add or subtract from the tail to get the desired revision
    if (a:direction == "older")
        let l:tail = l:tail - 1
    elseif (a:direction == "newer")
        let l:tail = l:tail + 1
    else
        echo "(rcsvers.vim) Error: Bad arg to s:NextCompareFiles() : a:direction"
    endif

    "put together the whole revision
    let s:revision = l:head . l:tail

    call s:CompareFiles(s:revision)

endfunction

" Function: Compare the current file to a revision {{{1
"------------------------------------------------------------------------------
function! s:CompareFiles(revision)

    let l:suffix = s:CreateSuffix()

    "save the current directory, in case they automatically change dir when opening files
    let l:savedir = expand("%:p:h")

    let l:rcsfile = s:GetSaveDirectoryName().expand("%:p:t").l:suffix

    " Build the co command
    "
    " co options are as follows:
    " -q        Keep co quiet ( no messages )
    " -p        Print the revision rather than storing in a file.
    "             This allows us to capture it with the r! command.
    " -r        Revision number to check out.
    " -x        Suffix to use for rcs files.

    let l:cmd = "co -q -p -r".a:revision

    if (g:rvSaveSuffixType != 0)
        let l:cmd = l:cmd." -x".l:suffix
    endif

    let l:cmd = l:cmd." ".g:rvFileQuote.bufname("%").g:rvFileQuote." ".
                \g:rvFileQuote.l:rcsfile.g:rvFileQuote

    " Create a new buffer to place the co output
    let l:tmpfile = g:rvTempDir.g:rvDirSeparator."_".expand("%:p:t").".".a:revision

    "save the buffer number of the original file
    let l:parent_bufnr = bufnr("%")

    " ditch any existing child buffer
    if (exists("s:child_bufnr"))
        sil exec bufwinnr(s:child_bufnr) . "wincmd w"
        sil exe "bd!"
    endif

    "create a new buffer
    sil exe "vnew ".l:tmpfile

    "save the buffer number of the revision file
    let l:child_bufnr = bufnr("%")

    " Delete the contents if it's not empty
    sil exe "1,$d"

    "change dir to the original file dir, in case they auto change dir
    "when opening files
    exec "cd ".g:rvFileQuote.l:savedir.g:rvFileQuote

    " Run the co command and capture the output
    sil exe "sil! 0r!".l:cmd
    setlocal noswapfile
    setlocal nomodified

    " Execute the outside compare program.
    if (g:rvCompareProgram !=? "This")
    " Write the file and quit it
        sil exe "w!"
        sil exe "bd!"

    sil exe "!".g:rvCompareProgram." " g:rvFileQuote.l:tmpfile.
                \g:rvFileQuote.' '.g:rvFileQuote.bufname("%").g:rvFileQuote
    else
    " or do a diff in the current instance of vim
        diffthis
        sil exec bufwinnr(l:parent_bufnr) . "wincmd w"
        diffthis

        "set session variables in the parent buffer which indicate parent buffer
        "number, child buffer number, and the revision that is
        "currently showing
        let s:parent_bufnr = l:parent_bufnr
        let s:child_bufnr = l:child_bufnr
        let s:revision = a:revision
    endif

endfunction
"}}}

" Default key mappings to generate a revision log, and diff with adjacent
" versions.
" You probably want to map these in your _vimrc to something easier to type, 
" like a function key.  Do it like this:
" re-map rcsvers.vim keys
"map <F8> \rlog
"map <F5> \older
"map <F6> \newer
"
"------------------------------------------------------------------------------
nnoremap <Leader>rlog :call <SID>DisplayLog()<cr>

nnoremap <Leader>older :call <SID>NextCompareFiles("older")<cr>
nnoremap <Leader>newer :call <SID>NextCompareFiles("newer")<cr>

let &cpo = s:save_cpo
" vim600:tw=78:set fdm=marker:

