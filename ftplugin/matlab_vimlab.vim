" MATLAB filetype plugin which facilitates working with MATLAB from Vim
" Language:	matlab
" Maintainer:	Jeroen de Haas <jeroen ThisPartMustBeIgnored at farjmp dot nl>
" Version: 0.1 released 19 Jan 2014
" License: {{{
" Copyright (c) 2014, Jeroen de Haas
" All rights reserved.
"
" Redistribution and use in source and binary forms, with or without
" modification, are permitted provided that the following conditions are met: 
"
" 1. Redistributions of source code must retain the above copyright notice, this
"    list of conditions and the following disclaimer. 
" 2. Redistributions in binary form must reproduce the above copyright notice,
"    this list of conditions and the following disclaimer in the documentation
"    and/or other materials provided with the distribution. 
"
"THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
"ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
"WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
"DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
"ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
"(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
"LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
"ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
"(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
"SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
" }}}
"  modified by yaj030
if !exists('g:matlab_quickfix_list')
	let g:matlab_quickfix_list="mlint"
endif
if !exists('g:delete_tmp_file_after')
	let g:delete_tmp_file_after=0
endif
if exists('b:did_matlab_vimlab_plugin')
	finish
endif

let b:did_matlab_vimlab_plugin = 1
let s:matlab_always_create = 0

" Define functions (run only once)
if !exists('s:matlab_extras_created_functions') || exists('s:matlab_always_create')
	runtime 'screen.vim'
	function! s:Warn(msg)
		echohl WarningMsg
		echo a:msg
		echohl Normal
	endfunction

	function! s:StartMatlab()
		let matlab_command = 'matlab -nodesktop -nosplash'
		let shell_command = 'ScreenShell'
		if exists('g:matlab_vimlab_vertical') && g:matlab_vimlab_vertical
			let shell_command = shell_command.'!'
		endif
		exe shell_command.' '.matlab_command
	endfunction

	function! s:TempOutputFilename()
		return "/tmp/vim_matlab_extras_".strftime('%s')
	endfunction

	function! s:Help(fun)
		"let tmp_file = call s:TempOutputFilename()
		let commands = "help ".a:fun.";"
		call g:ScreenShellSend(commands)
	endfunction

	function! s:Doc(command)
		call g:ScreenShellSend('doc '.a:command.';')
	endfunction

	function! s:ShowVar(var)
		call g:ScreenShellSend('whos '.a:var.';')
	endfunction

	function! s:SendLineToMatlab()
		exe '.'.'ScreenSend'
	endfunction

	function! s:SendSelectionToMatlab()
		exe '.'.'ScreenSend'
	endfunction

	function! s:SendSelectionToMatlabRevise()
		call s:CreateTmpMatlabFile()
		let b:VisualLineCounter+=1
		if b:VisualLineCounter==b:NumberOfSelectedLines+1
			call s:RunTmpFile()
		endif
		call s:DeleteTmpMatFile()
	endfunction

	function! s:RunTmpFile()
		let commands="cd('".expand("%:p:h")."');MatVimTmp;\n"
		call g:ScreenShellSend(commands)
	endfunction

	function! s:DeleteTmpMatFile()
		if g:delete_tmp_file_after==1
			silent! execute "!rm -f".expand("%:p:h")."/MatVimTmp.m"
			redraw!
		endif
	endfunction

	function! s:CreateTmpMatlabFile()
		if b:VisualLineCounter==1
			call s:CountSelectedLines()
			call s:SaveRegisterA()
			call s:AddTryToMfile()
			let @A="\t".getline(".")
			let @A="\n"
		else
			let @A="\t".getline(".")
			let @A="\n"
			if b:VisualLineCounter==b:NumberOfSelectedLines
				call s:AddCatchEndToMfile()
				call s:WriteRegisterAToFile()
			endif
		endif

		if b:VisualLineCounter==b:NumberOfSelectedLines+1
			call s:RestoreRegisterA()
		endif
	endfunction

	function! s:SaveRegisterA()
		let s:RegisterTmp=@a
	endfunction

	function! s:RestoreRegisterA()
		let @a=s:RegisterTmp
	endfunction

	function! s:CountSelectedLines()
		let b:FirstLineInSelection=line("'<")
		let b:LastLineInSelection=line("'>")
		let b:NumberOfSelectedLines=b:LastLineInSelection-b:FirstLineInSelection
		let b:NumberOfSelectedLines+=1
		let b:CurrentMatTmpLineOffset=b:FirstLineInSelection-3
	endfunction

	function! s:AddTryToMfile()
		let @a="try\n"
	endfunction

	function! s:AddCatchEndToMfile()
		let @A="catch MatlabErrorForVim\n"
		let @A="\tCurrentMatFile='".expand("%:p")."';\n"
		let @A="\tMfileTmpfileLineOffset=".b:CurrentMatTmpLineOffset.";\n"
		let @A="\tfileIDForVimError = fopen('/tmp/MatlabErrorForVim.err','w');\n"
		let @A="\tfor iiForVimError = numel(MatlabErrorForVim.stack):-1:1\n"
		let @A="\t\tswitch MatlabErrorForVim.stack(iiForVimError).name\n"
		let @A="\t\tcase 'MatVimTmp'\n"
		let @A="\t\t\tfprintf(fileIDForVimError,'Error in %s at line %d:\ %s\\n',CurrentMatFile, MatlabErrorForVim.stack(iiForVimError).line+MfileTmpfileLineOffset, 'refer to the command line');\n"
		let @A="\t\totherwise\n"
		let @A="\t\t\tfprintf(fileIDForVimError,'Error in %s at line %d:\ %s\\n',MatlabErrorForVim.stack(iiForVimError).file, MatlabErrorForVim.stack(iiForVimError).line, 'refer to the command line');\n"
		let @A="\t\tend\n"
		let @A="\tend\n"
		let @A="\tfclose(fileIDForVimError);\n"
		let @A="\trethrow(MatlabErrorForVim);\n"
		let @A="end\n"
		let @A="delete('/tmp/MatlabErrorForVim.err');\n"
	endfunction

	function! s:WriteRegisterAToFile()
		" silent! !rm -f /tmp/MatVimTmp.m
		" redir > /tmp/MatVimTmp.m
		execute "redir! >".expand("%:h")."/MatVimTmp.m"
		silent! echo @a
		redir END
		redraw!
	endfunction

	function! s:LoadMatErrToQuickfix()
		let s:CurrentErrorFormat = &errorformat
		setlocal errorformat=Error\ in\ %f\ at\ line\ %l:\ %m
		cfile /tmp/MatlabErrorForVim.err
		setlocal errorformat=s:CurrentErrorFormat
	endfunction

	function! s:RunMatFile()
		let commands="run('".expand("%:p")."');\n"
		call g:ScreenShellSend(commands)
	endfunction

	function! s:RunMatFileRevise()
		let words = []
		let line_number = 1
		while empty(words)
			let line_tmp = getline(line_number)
			let words = split(line_tmp)
			let line_number = line_number + 1
		endwhile
		let b:first_word = words[0]
		
		if b:first_word == "function"
			call s:RunMatFile()
		else
			call s:SaveRegisterA()
			let beginning = 1
			let ending = line('$')
			let b:CurrentMatTmpLineOffset=beginning-3
			call s:AddTryToMfile()
			exe beginning.','.ending.'yank A'
			call s:AddCatchEndToMfile()
			call s:WriteRegisterAToFile()
			call s:RunTmpFile()
			call s:RestoreRegisterA()
			call s:DeleteTmpMatFile()
		endif
	endfunction


	function! s:SendSectionToMatlab()
		let beginning = s:FirstLineInSection()
		let ending = s:LastLineInSection()
		exe beginning.','.ending.'ScreenSend'
	endfunction

	function! s:SendSectionToMatlabRevise()
		call s:SaveRegisterA()
		let beginning = s:FirstLineInSection()
		let ending = s:LastLineInSection()
		let b:CurrentMatTmpLineOffset=beginning-3
		call s:AddTryToMfile()
		exe beginning.','.ending.'yank A'
		call s:AddCatchEndToMfile()
		call s:WriteRegisterAToFile()
		call s:RunTmpFile()
		call s:RestoreRegisterA()
		call s:DeleteTmpMatFile()
	endfunction

	function! s:ClearMatlabScreen()
		call s:Clc()
	endfunction

	function! s:Clc()
		call g:ScreenShellSend('clc;')
	endfunction

	function! s:CloseAll()
		call g:ScreenShellSend('close all;')
	endfunction

	function! s:AddBreakpoint()
		let commands="addpath('".expand("%:p:h")."\')"
		call g:ScreenShellSend(commands)
		call g:ScreenShellSend("dbstop in ".bufname("%")." at ".line("."))
	endfunction

	function! s:RemoveBreakpoints()
		call g:ScreenShellSend("dbclear all")
	endfunction

	function! s:FirstLineInSection()
		let backwardmatch = search('^%%', 'Wbc')
		if backwardmatch < 1
			return 1
		else
			return backwardmatch
		endif
	endfunction

	function! s:LastLineInSection()
		let forwardmatch = search('^%%', 'Wn')
		if forwardmatch < 1
			return line('$')
		else
			return forwardmatch - 1
		endif
	endfunction

	function! s:NextSection()
		let forwardmatch = search('^%%', 'Wn')
		if forwardmatch < 1
			call s:Warn('At last chunk')
		else
			call cursor(forwardmatch, 1)
		endif
	endfunction

	function! s:PrevSection()
		let backwardmatch = search('^%%', 'Wbc')
		let gotoline = 1
		if backwardmatch > 0
			call cursor(backwardmatch)
			let backwardmatch = search('^%%', 'Wb')
			if backwardmatch < 1
				call s:Warn('At first chunk')
			else
				let gotoline = backwardmatch
			endif
		endif
		call cursor(gotoline, 1)
	endfunction

	function! s:CurrentWord()
		return expand("<cword>")
	endfunction

	function! s:DocCurrentWord()
		let curword = s:CurrentWord()
		call s:Doc(curword)
	endfunction 

	function! s:HelpCurrentWord()
		let curword = s:CurrentWord()
		call s:Help(curword)
	endfunction

	function! s:ShowCurrentVar()
		let curword = s:CurrentWord()
		call s:ShowVar(curword)
	endfunction

	function! s:SendSection()
		" find section
		let searchmatch = search('^%%', 'bcnW')
		if searchmatch < 1
			let searchmatch = 1
		endif
		let forwardmatch = search('^%%', 'Wn')
		if forwardmatch < 1
			let forwardmatch = line('$')
		else
			let forwardmatch -= 1
		endif
	endfunction
	let s:matlab_extras_created_functions=1
end

nnoremap <S-V> :let b:VisualLineCounter=1<CR> <S-V> 
nnoremap v :let b:VisualLineCounter=1<CR> v 
if g:matlab_quickfix_list=="error"
	let s:default_maps = [
				\ ['MatlabNextSection', 'gn', 'NextSection'],
				\ ['MatlabPrevSection', 'gN', 'PrevSection'],
				\ ['MatlabStart', '<leader>mm', 'StartMatlab'],
				\ ['MatlabDocCurrentWord', '<leader>md', 'DocCurrentWord'],
				\ ['MatlabHelpCurrentWord', '<leader>mh', 'HelpCurrentWord'],
				\ ['MatlabShowCurrentVar', '<leader>mv', 'ShowCurrentVar'],
				\ ['MatlabCurrentLine', '<leader>ml', 'SendLineToMatlab'],
				\ ['MatlabClearScreen', '<leader>mc', 'ClearMatlabScreen'],
				\ ['MatlabCloseAll', '<leader>mx', 'CloseAll'],
				\ ['MatlabAddBreakpoint', '<leader>mb', 'AddBreakpoint'],
				\ ['MatlabRemoveBreakpoints', '<leader>mB', 'RemoveBreakpoints'],
				\ ['MatlabSectionSend', '<leader>ms', 'SendSectionToMatlabRevise'],
				\ ['MatlabCurrentSelection', '<leader>me', 'SendSelectionToMatlabRevise'],
				\ ['MatlabRunFile', '<leader>mf', 'RunMatFileRevise'],
				\ ['LoadErrors', '<leader>mq', 'LoadMatErrToQuickfix'],
				\]
else
	let s:default_maps = [
				\ ['MatlabNextSection', 'gn', 'NextSection'],
				\ ['MatlabPrevSection', 'gN', 'PrevSection'],
				\ ['MatlabStart', '<leader>mm', 'StartMatlab'],
				\ ['MatlabSectionSend', '<leader>ms', 'SendSectionToMatlab'],
				\ ['MatlabDocCurrentWord', '<leader>md', 'DocCurrentWord'],
				\ ['MatlabHelpCurrentWord', '<leader>mh', 'HelpCurrentWord'],
				\ ['MatlabShowCurrentVar', '<leader>mv', 'ShowCurrentVar'],
				\ ['MatlabCurrentLine', '<leader>ml', 'SendLineToMatlab'],
				\ ['MatlabCurrentSelection', '<leader>me', 'SendSelectionToMatlab'],
				\ ['MatlabClearScreen', '<leader>mc', 'ClearMatlabScreen'],
				\ ['MatlabCloseAll', '<leader>mx', 'CloseAll'],
				\ ['MatlabRunFile', '<leader>mf', 'RunMatFile'],
				\ ['MatlabAddBreakpoint', '<leader>mb', 'AddBreakpoint'],
				\ ['MatlabRemoveBreakpoints', '<leader>mB', 'RemoveBreakpoints'],
				\]
endif

for [to_map, key, fn] in s:default_maps
	if !hasmapto('<Plug>'.to_map)
		exe "map <unique> <buffer> ".key." <Plug>".to_map
	endif
	exe "noremap <script> <buffer> <unique> <Plug>".to_map.
				\ " :call <SID>".fn."()<CR>"
endfor

if !exists(':MATDoc')
	command -nargs=1 MATDoc :call <SID>Doc(<f-args>)
endif

if !exists(':MATHelp')
	command -nargs=1 MATHelp :call <SID>Help(<f-args>)
endif
