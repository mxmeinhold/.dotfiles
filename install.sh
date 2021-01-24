#!/bin/bash

ERR="\e[1m\e[91m"
INFO="\e[1m\e[93m"
RESET="\e[0m"

function info {
    echo "${INFO}---> $1$RESET"
}

function err {
    echo "${ERR}---> $1$RESET"
}

dir=`pwd`

if [ -d symlink ]; then
    rm -rf symlink
fi
mkdir symlink

# cat prompt files
echo -e $(info "Assembling prompt config")
cat prompt/colour.sh prompt/prompt.sh > prompt/promptrc.symlink

# Git info statusline (git-radar)
echo -e $(info "Collecting git-radar")
mkdir -p git/git-radar.symlink
cd git/git-radar.symlink

git init &>/dev/null

if [[ `git remote` == *"git-radar"* ]]; then
    git remote update git-radar
fi
git remote add git-radar https://github.com/michaeldfallen/git-radar.git
git fetch --depth=1 -n -q git-radar
git checkout git-radar/master

cd $dir

# Main Configs
echo -e $(info "Linking primary config files")
for filename in */*.symlink; do
    cp -r $filename symlink/
    if [ -f ${filename}.local ]; then
        cat symlink/`basename $filename` ${filename}.local > symlink/.`basename $filename .symlink`
        rm symlink/`basename $filename`
    else
        mv symlink/`basename $filename` symlink/.`basename $filename .symlink`
    fi
    ln -sfn ${dir}/symlink/.`basename $filename .symlink` ~/.`basename $filename .symlink`
done

# Delet compiled promptrc
rm prompt/promptrc.symlink

# Aliases
for filename in */*.aliases; do
    if [ -f ${filename}.local ]; then
        cat $filename ${filename}.local > symlink/`basename $filename`
    else
        cp $filename symlink/
    fi
done

# Vim extras
echo -e $(info "Configuring Vim Extras")
./vimplugins.sh
cd ${dir}/vim/vim.d
for vim_dir in *; do
    mkdir -p $dir/symlink/.vim/$vim_dir
    cp $vim_dir/* $dir/symlink/.vim/$vim_dir/
done
cd $dir

cd symlink/.vim
mkdir -p ~/.vim
for vim_dir in *; do
    if [ -f ~/.vim/$vim_dir ] && [ ! -L ~/.vim/$vim_dir ]; then
        mv ~/.vim/$vim_dir ~/.vim/${vim_dir}.d.bak
    fi
    ln -sfn ${dir}/symlink/.vim/$vim_dir ~/.vim/$vim_dir
done
cd $dir

echo -e $(info "Linking bash_aliases")
mv symlink/bash.aliases symlink/.bash_aliases
ln -sfn ${dir}/symlink/.bash_aliases ~/.bash_aliases

cat symlink/*.aliases >> symlink/.bash_aliases
rm symlink/*.aliases

# i3lock script (copied to preserve -x)
echo -e $(info "Placing i3lock scripts")
mkdir -p ~/.local/bin
cp -f i3/* ~/.local/bin/

# Vim backup and undo dir
mkdir -p ~/.vim-tmp
