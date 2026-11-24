#!/bin/bash
#ROOM MANAGEMENT MODULE
#Hotel Booking Management System

#Locating the project database
ROOM_DB="$(cd "$(dirname "${BASH_SOURCE[0]}")/../database" && pwd)/rooms.txt"
BOOKING_DB="$(dirname "$ROOM_DB")/bookings.txt"

# 1.INITIALIZE DATABASE

room_init() {
    if [[ ! -d "$(dirname "$ROOM_DB")" ]]; then
        echo "Error: Database directory does not exist."
        return 1
    fi

    if [[ ! -e "$ROOM_DB" ]]; then
        touch "$ROOM_DB" || {
            echo "Error: Cannot create room database."
            return 1
        }
    fi

    if [[ ! -r "$ROOM_DB" || ! -w "$ROOM_DB" ]]; then
        echo "Error: Room database is not readable/writable."
        return 1
    fi
}

#2.VALIDATE ROOM NUMBER

room_validate_number() {
    [[ "$1" =~ ^[1-9][0-9]{0,5}$ ]]
}


# 3.VALIDATE ROOM TYPE


room_validate_type() {
    [[ "$1" == "AC" || "$1" == "Non-AC" ]]
}

# 4. VALIDATE ROOM STATUS

room_validate_status() {
    [[ "$1" == "Available" || "$1" == "Maintenance" ]]
}


#5. VALIDATE ROOM PRICE


room_validate_price() {
    [[ "$1" =~ ^[1-9][0-9]{0,7}$ ]]
}

#
#6. CHECK DUPLICATE ROOM


room_exists() {
    awk -F'|' -v room="$1" '
        $1 == room { found=1 }
        END { exit !found }
    ' "$ROOM_DB"
}

#7. ADD ROOM

add_room() {

    local room type status price

    echo
    echo "========== ADD NEW ROOM =========="

    read -rp "Enter room number: " room

    if ! room_validate_number "$room"; then
        echo "Invalid room number!"
        return
    fi

    if room_exists "$room"; then
        echo "Error: Room already exists!"
        return
    fi

    read -rp "Enter room type (AC/Non-AC): " type

    if ! room_validate_type "$type"; then
        echo "Invalid room type!"
        return
    fi

    read -rp "Enter room price per night: " price

    if ! room_validate_price "$price"; then
        echo "Invalid price! Enter a positive integer."
        return
    fi

    status="Available"

    printf '%s|%s|%s|%s\n' \
        "$room" "$type" "$status" "$price" >> "$ROOM_DB" || {
            echo "Error: Unable to save room."
            return 1
        }

    echo "Room added successfully!"
}


#8.DISPLAY ALL ROOMS


view_rooms() {

    echo
    echo "================ ROOM DETAILS ================"

    if [[ ! -s "$ROOM_DB" ]]; then
        echo "No rooms found."
        return
    fi

    printf "%-12s %-12s %-16s %-12s\n" \
        "ROOM NO" "TYPE" "STATUS" "PRICE"

    echo "------------------------------------------------"

    awk -F'|' '
        NF == 4 {
            printf "%-12s %-12s %-16s %-12s\n",
            $1, $2, $3, $4
        }
    ' "$ROOM_DB"

    echo "------------------------------------------------"
}

#9.SEARCH ROOM

search_room() {

    local room

    echo
    read -rp "Enter room number to search: " room

    if ! room_validate_number "$room"; then
        echo "Invalid room number!"
        return
    fi

    local result

    result=$(awk -F'|' -v room="$room" '
        $1 == room {
            printf "%s|%s|%s|%s", $1, $2, $3, $4
        }
    ' "$ROOM_DB")

    if [[ -z "$result" ]]; then
        echo "Room not found!"
    else
        echo
        echo "Room found!"
        echo "Room Number : $(cut -d'|' -f1 <<< "$result")"
        echo "Room Type   : $(cut -d'|' -f2 <<< "$result")"
        echo "Room Status : $(cut -d'|' -f3 <<< "$result")"
        echo "Room Price  : $(cut -d'|' -f4 <<< "$result")"
    fi
}

#10. CHECK ACTIVE BOOKINGS


room_has_active_booking() {

    [[ -f "$BOOKING_DB" ]] || return 1

    awk -F'|' -v room="$1" '
        $2 == room && ($6 == "Booked" || $6 == "Checked-In") {
            found=1
        }
        END { exit !found }
    ' "$BOOKING_DB"
}


#11. UPDATE ROOM


update_room() {

    local room type status price
    local temp_file

    echo
    read -rp "Enter room number to update: " room

    if ! room_validate_number "$room"; then
        echo "Invalid room number!"
        return
    fi

    if ! room_exists "$room"; then
        echo "Room not found!"
        return
    fi

    echo
    echo "1. Update Room Type"
    echo "2. Update Room Price"
    echo "3. Update Room Status"

    read -rp "Enter your choice: " choice

    case "$choice" in

        1)
            read -rp "Enter new type (AC/Non-AC): " type

            if ! room_validate_type "$type"; then
                echo "Invalid room type!"
                return
            fi

            temp_file=$(mktemp "${ROOM_DB}.XXXXXX") || return 1

            awk -F'|' -v OFS='|' -v room="$room" -v type="$type" '
                $1 == room { $2=type }
                { print }
            ' "$ROOM_DB" > "$temp_file"
            ;;

        2)
            read -rp "Enter new price: " price

            if ! room_validate_price "$price"; then
                echo "Invalid price!"
                return
            fi

            temp_file=$(mktemp "${ROOM_DB}.XXXXXX") || return 1

            awk -F'|' -v OFS='|' -v room="$room" -v price="$price" '
                $1 == room { $4=price }
                { print }
            ' "$ROOM_DB" > "$temp_file"
            ;;

        3)
            read -rp "Enter new status (Available/Maintenance): " status
            if ! room_validate_status "$status"; then
                echo "Invalid status!"
                return
            fi

            if [[ "$status" == "Maintenance" ]] &&
		room_has_active_booking "$room"; then
                echo "Cannot set room to Maintenance."
		echo "There is an active booking for this room."
                return
	    fi

            temp_file=$(mktemp "${ROOM_DB}.XXXXXX") || return 1

            awk -F'|' -v OFS='|' -v room="$room" -v status="$status" '
                $1 == room { $3=status }
		{ print }
            ' "$ROOM_DB" > "$temp_file"
            ;;
        *)
            echo "Invalid choice!"
            return
            ;;
    esac

    if [[ -z "$temp_file" || ! -s "$temp_file" ]]; then
	    echo "Error: Update failed."
        [[ -n "$temp_file" ]] && rm -f "$temp_file"
        return 1
    fi

    if mv "$temp_file" "$ROOM_DB"; then
        echo "Room updated successfully!"
    else
        echo "Error: Unable to save changes."
        rm -f "$temp_file"
        return 1
    fi
}

# 12. DELETE RO0M
delete_room() {

    local room confirm temp_file
    echo
    read -rp "Enter room number to delete: " room

    if ! room_validate_number "$room"; then
    	echo "Invalid room number!"
    	return
    fi

    if ! room_exists "$room"; then
    	echo "Room not found"
    fi

    if room_has_active_booking "$room"; then
    	echo "Cannot delete this room!"
        echo "An active booking exists for this room."
        return
    fi

    read -rp "Are you sure you want to delete this room? (y/n): " confirm

    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo "Deletion cancelled."
        return
    fi

    temp_file=$(mktemp "${ROOM_DB}.XXXXXX") || return 1

    awk -F'|' -v room="$room" '$1 != room' "$ROOM_DB" > "$temp_file"

    if mv "$temp_file" "$ROOM_DB"; then
        echo "Room deleted successfully!"
    else
        echo "Error: Unable to delete room."
        rm -f "$temp_file"
        return 1
    fi
}


# 13. ROOM MANAGEMENT MENU


room_menu() {

    room_init || return 1

    while true
    do
        echo
        echo "===================================="
        echo "         ROOM MANAGEMENT"
        echo "===================================="
        echo "1. Add Room"
        echo "2. View All Rooms"
        echo "3. Search Room"
        echo "4. Update Room"
        echo "5. Delete Room"
        echo "6. Back to Main Menu"
        echo "===================================="

        read -rp "Enter your choice: " choice

        case "$choice" in
            1) add_room ;;
            2) view_rooms ;;
            3) search_room ;;
            4) update_room ;;
            5) delete_room ;;
            6)
                echo "Returning to Main Menu..."
                break
                ;;
            *)
                echo "Invalid choice! Please enter 1-6."
                ;;
        esac
    done
}

