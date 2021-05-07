# youtube-dl-menu

A bash menu to download with youtube-dl.

It shows the different qualities available to the user, and allows to make the choice with a simple menu (it avoids to go through the -F & -f commands).

## Install & update

`curl https://raw.githubusercontent.com/Jocker666z/youtube-dl-menu/main/youtube-dl-menu.sh > /home/$USER/.local/bin/youtube-dl-menu && chmod +rx /home/$USER/.local/bin/youtube-dl-menu`

## Dependencies
`bc jq youtube-dl`

## Limitations:
* One file at a time
* Playlists are not supported
