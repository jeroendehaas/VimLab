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
		call g:ScreenShellSend('clc;')
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

	function! s:SendToMatlab()
		let beginning = s:FirstLineInSection()
		let end = s:LastLineInSection()
		exe beginning.','.end.'ScreenSend'
	endfunction

	function! s:SendLineToMatlab()
		exe '.'.'ScreenSend'
	endfunction

	function! s:SendSelectionToMatlab()
		exe '.'.'ScreenSend'
	endfunction

	" Run current script 
	function! s:RunMatFile()
		let commands="cd('".expand("%:p:h")."\'); run('".expand("%:p")."')\n"
		call g:ScreenShellSend(commands)
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

let s:default_maps = [
			\ ['MatlabNextSection', 'gn', 'NextSection'],
			\ ['MatlabPrevSection', 'gN', 'PrevSection'],
			\ ['MatlabStart', '<leader>mm', 'StartMatlab'],
			\ ['MatlabSend', '<leader>ms', 'SendToMatlab'],
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
