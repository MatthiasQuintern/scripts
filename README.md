# scripts
Some of the scripts I wrote.

# shell/config_sync.sh
A script that lets you easily manage your dotfiles/config files:
- create local backup
- push backup to git or other remote (e.g a VPS)
- pull backup from git or other remote
- install files from the backup
This is especially useful when you want to sync your dotfiles on multiple machines or if you plan a re-install of your os.
You can easily customize paths, remote adresses and most important, which (dot)files to sync.

If you sync your files to a server, make sure it has rsync installed.

This script uses sudo when it needs root rights to copy system dotfiles from/to /etc.

