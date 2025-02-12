# -*- mode: shell-script; -*-
alias unswap="sudo swapoff -a && sudo swapon -a"
alias tmux="tmux -2"
alias tt="tmux"
alias ta="tt a || tt"
alias man="TERM=xterm LC_ALL= w3mman"
which w3mman >/dev/null
if [ $? -eq 0 ];then
    alias man="TERM=xterm LC_ALL= w3mman"
fi
alias ls="ls --color=yes --group-directories-first"
alias ee="TERM=xterm-256color emacs -nw"
alias l="ls"
alias ec="TERM=xterm-256color emacsclient -a \"\" -t"
alias l1="ls -1"
alias ll="ls -lth"
alias la="ls -alh"
alias gia='git add .'
alias gib='git branch -vv'
alias gic='git checkout'
alias gif='git fetch'
alias gig='git merge'
alias gil='git log --oneline --graph --all --decorate'
currentver="$(git --version | awk -F' ' '{print $3}')"
requiredver="2.3.0"
if [ "$(printf "$requiredver\n$currentver" | sort -V | head -n1)" = "$currentver" ] && [ "$currentver" != "$requiredver" ];
then
    #echo "git less than 2.3.0 ($currentver)"
    alias gil="git log --graph --all --date=iso --pretty='format:%C(yellow)%h %C(green)%ad %C(bold blue)%an %C(auto)%d%C(reset) %s'"
else
    #echo "git greater than 2.3.0 ($currentver)"
    alias gil="git log --graph --all --date='format:%Y-%m-%d %H:%M:%S' --pretty='format:%C(yellow)%h %C(green)%ad %C(bold blue)%an %C(auto)%d%C(reset) %s'"
fi

alias gill='git pull'
alias gim='git commit'
alias gip='git push'
alias gis='git status'
alias gid='git diff'
alias myip='dig +short myip.opendns.com @resolver1.opendns.com'
alias ddo='docker-compose down'
alias dp='docker compose up | ccze -A'
alias dcl='docker compose logs -f --tail=10 | ccze -A'
alias dcu='docker compose up | ccze -A'
alias dcd='docker compose down'
alias dcb='docker compose build'
alias dcp='docker compose pull'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

if [ $BASH_VERSION ] && [ -f /usr/share/bash-completion/completions/git ]; then
    source /usr/share/bash-completion/completions/git
    __git_complete gia _git_add
    __git_complete gib _git_branch
    __git_complete gic _git_checkout
    __git_complete gil _git_log
    __git_complete gill _git_pull
    __git_complete gif _git_fetch
    __git_complete gim _git_commit
    __git_complete gip _git_push
    __git_complete gid _git_diff
fi

psg () { ps aux | grep -v grep | grep --color=yes "$@" ; }
genpw(){ < /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-12};echo;}
genpw2() {</dev/urandom tr -dc '{}()[]~12345!@#$%qwertQWERTasdfgASDFGzxcvbZXCV_B' | head -c14; echo;}
if [ $GDMSESSION ]; then
    if [ $GDMSESSION = "gnome" ]; then
	alias lkey="gsettings list-recursively org.gnome.desktop.wm.keybindings";
    fi
fi

export LESS=-iXFR

function parse_yaml() {
    local yaml_file=$1
    local prefix=$2
    local s
    local w
    local fs

    s='[[:space:]]*'
    w='[a-zA-Z0-9_.-]*'
    fs="$(echo @|tr @ '\034')"

    (
        sed -ne '/^--/s|--||g; s|\"|\\\"|g; s/\s*$//g;' \
            -e "/#.*[\"\']/!s| #.*||g; /^#/s|#.*||g;" \
            -e  "s|^\($s\)\($w\)$s:$s\"\(.*\)\"$s\$|\1$fs\2$fs\3|p" \
            -e "s|^\($s\)\($w\)$s[:-]$s\(.*\)$s\$|\1$fs\2$fs\3|p" |

            awk -F"$fs" '{
            indent = length($1)/2;
            if (length($2) == 0) { conj[indent]="+";} else {conj[indent]="";}
            vname[indent] = $2;
            for (i in vname) {if (i > indent) {delete vname[i]}}
                if (length($3) > 0) {
                    vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
                    printf("%s%s%s%s=(\"%s\")\n", "'"$prefix"'",vn, $2, conj[indent-1],$3);
                }
            }' |

            sed -e 's/_=/+=/g' |
            awk 'BEGIN {
                 FS="=";
                 OFS="="
             }
             /(-|\.).*=/ {
                 gsub("-|\\.", "_", $1)
             }
             { print }'

    ) < "$yaml_file"
}

function create_variables() {
    local yaml_file="$1"
    eval "$(parse_yaml "$yaml_file")"
}

function ff() {
    docker compose run -u root --rm --no-deps --entrypoint "bash -c \"chown -R odoo: /var/lib/odoo/ && chown `id -u`:`id -g` -R /mnt/extra-addons\"" odoo
    [ $? -eq 0 ] || echo "Operation failed"
}

lg () {
    case "$#" in
	1) ls | grep -i "$@" ;;
	2) ls "$2" | grep -i "$1" ;;
	*) echo "Too much arguments for this command" ;;
    esac
}

lsg () {
    case "$#" in
	1) ls -alh | grep -i "$@" ;;
	2) ls -alh "$2" | grep -i "$1" ;;
	*) echo -e "Find files matching a pattern in a directory (defaults to current directory if no location given)\n\nUsage: lsg file-pattern [location]\nExample: lsg lola ~/Documents\n\n" ;;
    esac
}

function fp (){
    # unzipping a zip file lead to a directory tree with loosy permissions 700
    # It happens with downloaded odoo modules from odoo app store
    # The unzipped module is then invisible to the odoo application
    # This function tune the right permissions
    find . -type d -exec chmod 755 {} \;
    find . -type f -exec chmod 644 {} \;
    # TODO: Make it accept an argument and defaults to current dir
}

function mount_nfs () {
    if ! dpkg -s nfs-common &> /dev/null ;then
        sudo apt -y install nfs-common
    fi

    # create nfs_share folder if doesn t exists
    if [ ! -d ~/nfs_share ]; then
	mkdir ~/nfs_share
    fi
    sudo mount -t nfs 192.168.1.10:/home/aziz/partage ~/nfs_share -o noatime,nodiratime,relatime,soft,nfsvers=4.0,async,rsize=65536,wsize=65536
}

function install_cron () {
    if ! crontab -l | grep synch_ssh_config &>/dev/null ; then
        crontab -l | { cat; echo "*/10 8-17 * * sat,sun,mon,tue,wed,thu $HOME/.dotfiles/bin/synch_ssh_config" ; } | crontab -
    fi
}
install_cron

function __ssh_completion () {
    perl -ne 'print "$1 " if /^[Hh]ost (.+)$/' ~/.ssh/config.d/ssh_config
}

if [ -f ~/.ssh/config.d/ssh_config ]; then
    complete -W "$(__ssh_completion)" ssh;
fi

function ensure_ssh_include()
{
    if [ ! -f ~/.ssh/config ]; then
        touch ~/.ssh/config
    fi
    if ! grep 'Include "config.d/ssh_config"' ~/.ssh/config &>/dev/null; then
        echo 'Include "config.d/ssh_config"' >> ~/.ssh/config
    fi
}
ensure_ssh_include

function scaffold(){
    if [ $# -eq 0 ] ; then
        echo "Give a name to your project"
    else
        docker compose run -u root --rm --no-deps --entrypoint "bash -c \"odoo scaffold ${1} /mnt/extra-addons  && chown `id -u`:`id -g` -R /mnt/extra-addons/${1}\"" odoo
    fi
    cd extra-addons/${1}
}

function dip ()
{
    docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $@
}

function dls ()
{
    docker container ls --format "{{.Names}}"
}


function dlsip ()
{
    MAX=6
    container_list=$(dls)
    if [ ! -z "$container_list" ] ; then
        container_count=$(wc -l <<< "$container_list")
    else
        echo "No container running"
        return 2;
    fi

    if [ $container_count -lt $MAX ];then
        while read container; do
            printf "%20s\t:\t%s\n" $container $(dip $container);
        done <<< "$container_list"
    else
        echo "Too many containers. Output ${MAX} from total ${container_count}"
        while read container; do
            printf "%20s\t:\t%s\n" $container $(dip $container);
        done <<EOF
$(head -$MAX <<< "$container_list")
EOF
    fi
}
