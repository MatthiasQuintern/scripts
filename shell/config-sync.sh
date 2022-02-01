#/bin/bash
# Made by Matthias Quintern
# 11/2021
# This software comes with no warranty.

# ABOUT
# Copies all (dot)files listed in user_dotfiles and system_dotfiles to CONFIG_DIR
# If you pass strings as parameters, only dotfiles that contain at least one of the strings are processed.

#
# SETTINGS
#
# do not append trailing '/'
# directories where configs will be copied to
CONFIG_DIR=~/Sync/dotfiles
# directories where configs are backuped when updating your configs with the ones from $CONFIG_DIR
BACKUP_DIR=~/Sync/rsync_backup

# GIT
GIT_REPO="https://github.com/MatthiasQuintern/dotfiles"
GIT_BRANCH="master"

# REMOTE
REMOTE_DIR="matthias@quintern.xyz:/home/matthias/dotfiles"
REMOTE_PORT=69

# rsync with -R will place the files relative to the ., so 
# ~/./.config/conf -> $CONFIG_DIR/home/.config/conf
# append trailing slashes to directories
# could just as well left ~/./ out and make it copy everything to $HOME, but then vim would not suggest the correct filepath :()
declare -a user_dotfiles=(\
    ~/./.zshrc 
    ~/./.bashrc 
    ~/./.aliasrc 
    ~/./.config/ranger/rc.conf
    ~/./.config/ranger/rifle.conf
    ~/./.vimrc 
    ~/./.vim/cocrc.vim
    ~/./.vim/sessions
    ~/./.config/strawberry/strawberry.conf
    # ~/./.config/xfce4/terminal/terminalrc
    ~/./.config/xfce4/
    ~/./.config/bspwm/bspwmrc
    ~/./.config/sxhkd/sxhkdrc
    ~/./.config/polybar/
    ~/./.config/picom.conf
    ~/./.config/khard/khard.conf
    ~/./.config/khal/config
    ~/./.config/neofetch/
    ~/./.ssh/config
    ~/./.config/rncbc.org/QjackCtl.conf
    ~/./memo.md
)
declare -a system_dotfiles=(\
   /etc/./pacman.conf
    /etc/./lxdm/lxdm.conf
    # Where the XDG_..._HOME variables are defined
    /etc/./security/pam_env.conf
    /etc/./xdg/xfce4/
    /etc/./sudoers
    /etc/./X11/xorg.conf.d/00-keyboard.conf
    /etc/./udev/rules.d/99-mount-usb.rules
)

#
# UTILITY
#
FMT_MESSAGE="\e[1;34m%s\e[0m\n"
FMT_ERROR="\e[1;31mERROR: \e[0m%s\n"
FMT_BACKUP="\e[1;32mBacking Up:\e[0m %s\n"
FMT_UPDATE="\e[1;33mUpdating:\e[0m %s\n"
FMT_CONFIG="\e[34m%s\e:\t\e[1;33m%s\e[0m\n"

# check if a passed parameter is contained in file
check_file_in_args()
{
    if [ $ALL = 1 ]; then
        return 0
    fi
    for string in ${FILES[@]}; do
        if [[ $file == *$string* ]]; then
            return 0
        fi
    done
    return 1
}


# check if pwd is root of git repo
check_git_repo()
{
    if [ -d .git ]; then
        return 0
    else
        return 1
    fi
}

check_rsync()
{
    if ! command -v rsync &> /dev/null; then
        printf "$FMT_ERROR" "rsync is not installed. Please install rsync."
        exit 1
    fi
}
check_git()
{
    if ! command -v git &> /dev/null; then
        printf "$FMT_ERROR" "git is not installed. Please install git."
        exit 1
    fi
}

#
# SAVE CONFIGS
#
# copy configs from arrays in $CONFIG_DIR
save_configs()
{
    # make directories 
    mkdir -p $CONFIG_DIR/home
    mkdir -p $CONFIG_DIR/etc

    for file in "${user_dotfiles[@]}"; do
        if check_file_in_args; then
            printf "$FMT_BACKUP" "$file"
            rsync -aR $file $CONFIG_DIR/home
        fi
    done

    for file in "${system_dotfiles[@]}"; do
        if check_file_in_args; then
            printf "$FMT_BACKUP" "$file"
            sudo rsync -aR $file $CONFIG_DIR/etc

            # sudoers permissions
            if [ $file == "/etc/./sudoers" ]; then
                printf "$FMT_MESSAGE" "Warning: Making sudoers readable for users (necessary for push/pull, but potential security risk)."
                sudo chmod a+r $CONFIG_DIR/etc/sudoers
            fi
        fi
    done
}


#
# UPDATE CONFIGS
#
update_all_configs()
{
    # update user configs
    printf "$FMT_MESSAGE" "Updating all user configs"
    rsync -aRu --backup-dir $BACKUP_DIR/home $CONFIG_DIR/home $HOME

    # update system configs
    printf "$FMT_MESSAGE" "Updating all system configs"
    sudo rsync -aRu --backup-dir $BACKUP_DIR/etc $CONFIG_DIR/etc /etc
}

update_configs()
{
    mkdir -p $BACKUP_DIR/home &&
    mkdir -p $BACKUP_DIR/etc || {
        printf "$FMT_ERROR" "Can not create backup directories, exiting now. No installed file will be updated."
        exit 1
    }

    for file in "${user_dotfiles[@]}"; do
        if check_file_in_args; then
            mkdir -p $(dirname $file)
            file=$(echo $file | sed "s|.*/\./||") # remove ~/./ from the filename
            printf "$FMT_UPDATE" "$file"
            rsync -a --backup-dir $BACKUP_DIR/home $CONFIG_DIR/home/$file $HOME/$file
        fi
    done

    for file in "${system_dotfiles[@]}"; do
        if check_file_in_args; then
            mkdir -p $(dirname $file)
            file=$(echo $file | sed "s|/etc/||") # remove /etc/ from the filename
            printf "$FMT_UPDATE" "$file"

            # sudoers permissions, must come before copying sudoers since sudo doesnt work when owned by user
            if [ $file == "./sudoers" ]; then
                printf "$FMT_MESSAGE" "Making sudoers in system readable only for root"
                sudo chmod a-rwx $CONFIG_DIR/etc/sudoers
                sudo chown root $CONFIG_DIR/etc/sudoers
            fi

            sudo rsync -a --backup-dir $BACKUP_DIR/etc $CONFIG_DIR/etc/$file /etc/$file

            # change ownership to root
            sudo chown root:root /etc/$file

            # change perm back
            if [ $file == "./sudoers" ]; then
                sudo chmod a+r $CONFIG_DIR/etc/sudoers
            fi

        fi
    done
}


git_push()
{
    echo $PWD
    if ! check_git_repo; then
        printf "$FMT_ERROR" "$PWD is not a git repo."
        read -p "Initialise git repo here? [y/n]: " answer
        case $answer in
            y|Y)
                git init &&
                git add -A &&
                git commit -m "initial commit" &&
                git branch -M $GIT_BRANCH &&
                printf "$FMT_MESSAGE" "Adding origin: $GIT_REPO" &&
                git remote add origin $GIT_REPO ||
                {
                    printf "$FMT_ERROR" "Something went wrong while setting up git repo."
                    exit 1
                }
                ;;
            *)
                printf "$FMT_MESSAGE" "Cancelled"
                exit 0
                ;;
        esac
    fi

    git add -A &&
    git commit &&
    printf "$FMT_MESSAGE" "Pushing repo" &&
    git push -u origin $GIT_BRANCH ||
    printf "$FMT_ERROR" "Something went wrong: Could not push repo."
}


git_pull()
{
    if ! check_git_repo; then
        printf "$FMT_ERROR" "$PWD is not a git repo."
        echo "Initialise git repo from remote \"$GIT_REPO\" here?"
        read -p "[y/n]: " answer
        case $answer in
            y|Y)
                git init &&
                printf "$FMT_MESSAGE" "Adding origin: $GIT_REPO" &&
                git remote add origin $GIT_REPO &&
                git fetch origin &&
                printf "$FMT_MESSAGE" "Checking out branch \"$GIT_BRANCH\" of origin" &&
                git checkout $GIT_BRANCH ||
                {
                    printf "$FMT_ERROR" "Something went wrong while setting up git repo."
                    exit 1
                }
                exit 0
                ;;
            *)
                printf "$FMT_MESSAGE" "Cancelled"
                exit 0
                ;;
        esac
    fi

    printf "$FMT_MESSAGE" "Pulling repo"
    git pull ||
    printf "$FMT_ERROR" "Something went wrong: Could not pull repo."
}


#
# REMOTE SERVER
#
remote_push()
{
    printf "$FMT_MESSAGE" "Pushing to remote: $REMOTE_DIR"
    rsync -avu -e "ssh -p $REMOTE_PORT" $CONFIG_DIR/ $REMOTE_DIR ||
    printf "$FMT_ERROR" "Something went wrong: Could not push to remote."
}

remote_pull()
{
    printf "$FMT_MESSAGE" "Pulling from remote: $REMOTE_DIR"
    rsync -avu -e "ssh -p $REMOTE_PORT" $REMOTE_DIR/ $CONFIG_DIR ||
    printf "$FMT_ERROR" "Something went wrong: Could not pull from remote."
}
    

#
# HELP
#
show_help()
{
    printf "\e[34mFlags:\e[33m
Argument        Short   Install:\e[0m
--help          -h      show this
--settings      -s      show current settings

--backup        -b      copy dotfiles to \$CONFIG_DIR
--update        -u      copy dotfiles from \$CONFIG_DIR into the system, current dotfiles are backed up to \$BACKUP_DIR
--all           -a      apply operation to all dotfiles

--git-pull              pull dotfiles from git repo
--git-push              push dotfiles to git repo      
--remote-pull           pull dotfiles from remote location (eg. vps)
--remote-push           push dotfiles to remote location

Any argument without a '-' is interpreted as part of a filepath/name and the selected operation will only be applied to files containing the given strings.
The order for multiple actions is: backup -> git pull/push -> remote pull/push -> update
Pull/Push operations always affect all the files in the \$CONFIG_DIR, but not the files that are actually installed.
"
}


show_settings()
{
    printf "\e[1mThe current settings are:\e[0m\n"
    printf "$FMT_CONFIG" \$CONFIG_DIR "$CONFIG_DIR"
    printf "$FMT_CONFIG" \$BACKUP_DIR "$BACKUP_DIR"
    printf "$FMT_CONFIG" \$GIT_REPO "$GIT_REPO"
    printf "$FMT_CONFIG" \$GIT_BRANCH "$GIT_BRANCH"
    printf "$FMT_CONFIG" \$REMOTE_DIR "$REMOTE_DIR"
    printf "$FMT_CONFIG" \$REMOTE_PORT "$REMOTE_PORT"
}


#
# PARSE ARGS
#
if [ -z $1 ]; then
    show_help
    exit 0
fi



BACKUP=0
UPDATE=0
GIT_PULL=0
GIT_PUSH=0
REMOTE_PULL=0
REMOTE_PUSH=0
ALL=0
# all command line args with no "-" are interpreted as part of filepaths. 
FILES=""
while (( "$#" )); do
    case "$1" in
        -h|--help)
            show_help
            exit 0 ;;
        -s|--settings)
            show_settings
            exit 0 ;;
        -b|--backup)
            BACKUP=1
            shift ;;
        -u|--update)
            UPDATE=1
            shift ;;
        -a|--all)
            ALL=1
            shift ;;
        --git-pull)
            GIT_PULL=1
            shift ;;
        --git-push)
            GIT_PUSH=1
            shift ;;
        --remote-pull)
            REMOTE_PULL=1
            shift ;;
        --remote-push)
            REMOTE_PUSH=1
            shift ;;
        -*|--*=) # unsupported flags
            printf "$FMT_ERROR" "Unsupported flag $1" >&2
            exit 1 ;;
        *) # everything that does not have a - is interpreted as filepath
            FILES="$FILES $1"
            shift ;;
    esac
done


# 
# RUN THE FUNCTIONS
#
# create and cd CONFIG_DIR
cd $CONFIG_DIR || {
    mkdir -p $CONFIG_DIR
    cd $CONFIG_DIR || {

        printf "$FMT_ERROR" "Can not create config dir: $CONFIG_DIR"
        exit 1
    }
}

# order: 
#  backup - git-push - remote-push - git-pull - remote-pull - update
if [ $BACKUP = 1 ]; then
    check_rsync
    save_configs
fi
if [ $GIT_PUSH = 1 ]; then
    check_git
    git_push
fi
if [ $GIT_PULL = 1 ]; then
    check_git
    git_pull
fi
if [ $REMOTE_PUSH = 1 ]; then
    check_rsync
    remote_push
fi
if [ $REMOTE_PULL = 1 ]; then
    check_rsync
    remote_pull
fi
if [ $UPDATE = 1 ]; then
    check_rsync
    update_configs
fi
