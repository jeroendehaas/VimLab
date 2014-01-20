# VimLab
VimLab tries to replicate MATLAB's support for code sections in Vim. It uses
tmux to maintain a MATLAB session from within vim.



## Requirements
VimLab relies on tmux and screen.vim to set up and communicate with a MATLAB
session and expects matlab to be on your `$PATH`. Automatic code analysis is
provided by the excellent syntastic plugin if the mlint command (provided by
MATLAB) is on your path as well. 

### tmux
VimLab requires vim to run inside a tmux session. Linux users may find a tmux
package is provided by their favorite distribution. For OS X users, I recommend
installing tmux using [homebrew](http://brew.sh). 

For a well written introduction to tmux, please take a look at the book ["tmux:
Productive Mouse-Free Development"](http://pragprog.com/book/bhtmux/tmux) by
Brian P. Hogan. 

### screen.vim
VimLab uses [Screen.vim](https://github.com/ervandew/screen) to launch MATLAB in
a new pane and the communication between vim and MATLAB. 

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
* `\ms` sends section the cursor is in to MATLAB
* `\md` open the documentation for the current word
* `\mh` show help for the current word
* `\mv` show the variable the current is on
* `gn`  go to the next section
* `gN`  go to the previous section

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
