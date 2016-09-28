# VimLab 
VimLab replicates MATLAB's support for code sections in Vim. It uses
tmux to maintain a MATLAB session from within vim.

## Requirements
VimLab relies on tmux and screen.vim which are used to set up and communicate
with a MATLAB session. It expects the `matlab` command to be on your `$PATH`.
Code analysis, similar to that offered by MATLAB's editor, is provided by the
excellent Syntastic plugin. If `mlint` is on your path as well, Syntastic will
automatically analyze your MATLAB code when it's saved.

### tmux
VimLab requires vim to run inside a tmux session. Linux users may find a tmux
package is provided by their favorite distribution. For OS X users, I recommend
installing tmux using [homebrew](http://brew.sh). 

For a well written introduction to tmux, please take a look at the book ["tmux:
Productive Mouse-Free Development"](http://pragprog.com/book/bhtmux/tmux) by
Brian P. Hogan. 

### screen.vim
VimLab uses [Screen.vim](https://github.com/ervandew/screen) to manage a MATLAB
session within tmux.

### Syntastic (Optional)
Install [Syntastic](https://github.com/scrooloose/syntastic) if you wish to have
your MATLAB code automatically analyzed when it is saved. 
 
## Installation
I recommend installing VimLab using [Vundle](https://github.com/gmarik/vundle).
Add the following lines to your .vimrc file:
```vim
Bundle "ervandew/screen"
Bundle "dajero/VimLab"
"Optional, if you desire automatic code analysis
Bundle "scrooloose/syntastic"
```
Next, either quit and relaunch vim or source `.vimrc` from within your current
vim session. Finally, issue the `:BundleInstall` command to vim to install
VimLab and its dependencies.

## Usage
VimLab automatically creates a few key mappings when you enter a MATLAB buffer.
These mappings are prefixed by your leader, which defauls to `\`. If you set
your mapleader to a different character, please mentally substitute the
backslash by the `mapleader` of your choice. 

* `\mm` starts matlab
* `\ms` sends the current section to MATLAB
* `\md` open the documentation for the current word
* `\mh` show help for the current word
* `\mv` show the variable the cursor is on
* `gn`  go to the next section
* `gN`  go to the previous section

## updated commands (By Yanfei)
* `\me` send selection to Matlab
* `\ml` send current line to Matlab
* `\mf` run current file
* `\mc` clear Matlab screen
* `\mx` close all figures
* `\mq` load errors (only if you choose g:matlab_quickfix_list='error'
* `\mb` add break point
* `\mB` delete all break points

VimLab also provides two commands to quickly open the documentation or help for
a function:
* `:MATDoc my-function` opens the documentation for my-function
* `:MATHelp my-function` shows help for my-function

## Configuration
By default, VimLab splits your tmux window horizontally to create a pane for
MATLAB. If instead, you prefer the panes to be arranged vertically, set the
varible `g:matlab_vimlab_vertical` to `1`, e.g. add the following line to your
`.vimrc`:
```vim
let g:matlab_vimlab_vertical=1
```

## Configuration Error and quickfix list (By Yanfei)
By default, if you installed Fabrice's Matlab plugin, :make call mlint to generate warns and messages. But if you want to use quickfix list to handle real errors, set `g:matlab_quickfix_list` to `error`. Everytime you see errors, press \mq to load them to quickfix list, then you can use cn cp clist etc.

The basic idea is to copy all the lines you want to run in a MatVimTmp.m file in the same folder which uses try..catch to handle errors and saves them in the /tmp/MatlabErrorForVim.err. Then they can be loaded by calling the cfile() vim buildin function.  You can set g:delete_tmp_file_after=1, and the MatVimTmp.m will be deleted after you run it. 

If you don't want quickfix list to handle errors and don't set 'g:matlab_quickfix_list', the approach will be the original approach. No temporary file will be created. All the lines are just copied to the Matlab command window. 




