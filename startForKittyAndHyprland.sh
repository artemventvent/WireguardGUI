#!/bin/bash
hyprctl keyword windowrulev2 "float, class:kitty, title:(Wireguard GUI)"

kitty --hold --title "Wireguard GUI" -e bash -c "
sh /home/user/Scripts/WireguardGui.sh
"