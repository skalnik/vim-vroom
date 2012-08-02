vroom.vim
=========

Run your Ruby tests! Supports RSpec, Test::Unit/MiniTest, and Cucumber. For more
information, check out the
[documentation](http://vim-doc.heroku.com/view?https://raw.github.com/skalnik/vim-vroom/master/doc/vroom.txt)
(available in Vim after installation `:help vroom`)

Installation
------------

Check out [vundle](https://github.com/gmarik/vundle) or
[pathogen.vim](https://github.com/tpope/vim-pathogen) and then install:

### vundle

Add the following to your `.vimrc` after vundle setup:

    Bundle 'skalnik/vim-vroom'

and remember to run `:BundleInstall`.

### pathogen

Copy and paste:

    $ cd ~/.vim/bundle
    $ git clone 'git://github.com/skalnik/vim-vroom.git'


Oddities
--------

If you're using MacVim & rbenv and your tests are running under the wrong Ruby version, check out
[this](http://vim.1045645.n5.nabble.com/MacVim-and-PATH-td3388705.html#a3392363) fix.

Credit
------

I first stumbled upon this snippet of code in [Gary Bernhardt's
.vimrc](https://github.com/garybernhardt/dotfiles/blob/master/.vimrc), and have
modified it, turned it into a plugin and begun improving it. [Steven
Harman](http://github.com/stevenharman) also provided inspiration in the
creation of the plugin, cucumber support, and Gemfile detection.
