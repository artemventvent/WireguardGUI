#!/bin/bash

CONFIG_FILE="$HOME/.vpn_interface"
mainInterface=""
sudoPassword=""

get_sudo_password() {
    while true; do
        sudoPassword=$(dialog --title "Enter Password" --passwordbox "Enter your sudo password:" 8 40 3>&1 1>&2 2>&3)
        echo "$sudoPassword" | sudo -S echo "" >/dev/null 2>&1
        if [ $? -eq 0 ]; then
            break
        else
            dialog --msgbox "Incorrect password. Please try again." 6 40
        fi
    done
}

load_last_interface() {
    if [ -f "$CONFIG_FILE" ]; then
        mainInterface=$(cat "$CONFIG_FILE")
    fi
}

save_current_interface() {
    echo "$mainInterface" > "$CONFIG_FILE"
}

manage_interfaces() {
    while true; do
        interfaces=($(echo "$sudoPassword" | sudo -S ls /etc/wireguard 2>/dev/null | xargs -n 1 basename))
        
        if [ ${#interfaces[@]} -eq 0 ]; then
            interfaces=("No available interfaces")
        fi

        menu_items=()
        for i in "${!interfaces[@]}"; do
            menu_items+=("$i" "${interfaces[$i]}")
        done

        selected=$(dialog --title "Interface Selection" \
            --menu "Available interfaces:" 20 50 10 \
            "${menu_items[@]}" \
            3>&1 1>&2 2>&3)

        if [ $? -ne 0 ]; then
            break
        fi

        interface="${interfaces[$selected]}"

        choice=$(dialog --title "Interface Management" \
            --menu "Selected: $interface" 15 50 3 \
            1 "Add New Interface" \
            2 "Set as Primary" \
            3 "Delete" \
            3>&1 1>&2 2>&3)

        case $choice in
            1)
                filepath=$(dialog --title "Add Interface" \
                    --inputbox "Enter the full path to the configuration file:" 10 60 \
                    3>&1 1>&2 2>&3)
                if [ -n "$filepath" ]; then
                    echo "$sudoPassword" | sudo -S cp "$filepath" /etc/wireguard/
                    if [ $? -eq 0 ]; then
                        dialog --msgbox "Interface added successfully." 6 40
                    else
                        dialog --msgbox "Error adding interface." 6 40
                    fi
                fi
                ;;
            2)
                mainInterface="${interface%.conf}"
                save_current_interface
                dialog --msgbox "Interface $mainInterface set as primary." 6 40
                ;;
            3)
                echo "$sudoPassword" | sudo -S rm -f "/etc/wireguard/$interface"
                if [ $? -eq 0 ]; then
                    dialog --msgbox "Interface $interface deleted successfully." 6 40
                else
                    dialog --msgbox "Error deleting interface." 6 40
                fi
                ;;
        esac
    done
}

get_sudo_password
load_last_interface

while true; do
    choice=$(dialog --title "Wireguard GUI" --menu "Choose an action" 15 50 5 \
        1 "Connect" \
        2 "Disconnect" \
        3 "Status" \
        4 "Select Interface" \
        5 "Exit" \
        3>&1 1>&2 2>&3)

    case $choice in
        1)
            if [ -n "$mainInterface" ]; then
                echo "$sudoPassword" | sudo -S wg-quick up "$mainInterface"
                if [ $? -eq 0 ]; then
                    dialog --msgbox "VPN $mainInterface started successfully!" 6 40
                else
                    dialog --msgbox "Error starting VPN $mainInterface." 6 40
                fi
            else
                dialog --msgbox "Please select an interface first." 6 40
            fi
            ;;
        2)
            if [ -n "$mainInterface" ]; then
                echo "$sudoPassword" | sudo -S wg-quick down "$mainInterface"
                if [ $? -eq 0 ]; then
                    dialog --msgbox "VPN $mainInterface stopped successfully!" 6 40
                else
                    dialog --msgbox "Error stopping VPN $mainInterface." 6 40
                fi
            else
                dialog --msgbox "Please select an interface first." 6 40
            fi
            ;;
        3)
            if [ -n "$mainInterface" ]; then
                vpn_status=$(echo "$sudoPassword" | sudo -S wg show "$mainInterface" 2>/dev/null || echo "VPN $mainInterface is not running.")
                dialog --msgbox "$vpn_status" 20 60
            else
                dialog --msgbox "Please select an interface first." 6 40
            fi
            ;;
        4)
            manage_interfaces
            ;;
        5)
            kill -HUP $PPID
            ;;
    esac
done
