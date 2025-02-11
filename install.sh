#!/bin/bash

current_dir=$PWD;
homeconfig="
bash_aliases
fire_tmux.bash
inputrc
tmux.conf
vimrc
"

# Crée un lien symbolique des fichiers de configuration vers le
# contenu de ce dossier

for fichier in $homeconfig; do
    if [ ! -f $HOME/.$fichier ] ; then
	ln -s $current_dir/$fichier $HOME/.$fichier
	echo "~/.$fichier a été créé"
    else
	echo "~/.$fichier exist déjà"
    fi
done

# S'assure que le fichier $HOME/.profile n'est pas un lien
# Si oui le remplacer par le template système

if [ -h $HOME/.profile ];then
    rm $HOME/.profile;
    cp /etc/skel/.profile $HOME;
fi


END_SEGMENT=$(sed -n '/^#END NB dotfiles/p' ~/.profile)
[ ! -z "$END_SEGMENT" ] && sed -i '/^#BEGIN NB dotfiles/,/^#END NB dotfiles/d' ~/.profile


cat <<EOF >> ~/.profile
#BEGIN NB dotfiles
# Do not add anything in between BEGIN and END

# Force colored prompt
force_color_prompt=yes

# Set the station ENV variable
export ENV=$ENV

# Enable curses pinentry for GPG password
export GPG_TTY=\$(tty)

if [ -d "\$HOME/.local/bin" ] ; then
    PATH="\$HOME/.local/bin:\$PATH"
fi

if [ -f $current_dir/fire_tmux.bash ]; then
    source $current_dir/fire_tmux.bash
fi

#END NB dotfiles
EOF

# Charger les aliases
source ~/.bash_aliases

# Créer un template dir pour les hooks de git
git config --global init.templateDir $current_dir/gitemplates
