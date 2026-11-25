
#!/bin/bash

# Customer database
CUSTOMER_DB="$(cd "$(dirname "${BASH_SOURCE[0]}")/../database" && pwd)/customers.txt"

# ==========================================
# 1. ADD CUSTOMER
# ==========================================

customer_add() {

    local name phone email id

    echo
    echo "========== ADD CUSTOMER =========="

    read -rp "Enter name: " name

    if [[ ! "$name" =~ ^[a-zA-Z][a-zA-Z\ \'-]{1,48}$ ]]; then
        echo "Invalid name!"
        return
    fi

    read -rp "Enter phone number: " phone

    if [[ ! "$phone" =~ ^[0-9]{10}$ ]]; then
        echo "Invalid phone number!"
        return
    fi

    read -rp "Enter email: " email

    if [[ ! "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        echo "Invalid email!"
        return
    fi

    # Generate unique customer ID
    id=$(awk -F'|' '
        $1 ~ /^C[0-9]+$/ {
            n=substr($1,2)+0
            if(n>max) max=n
        }
        END {printf "C%03d", max+1}
    ' "$CUSTOMER_DB")

    echo "$id|$name|$phone|$email" >> "$CUSTOMER_DB"

    echo "Customer added successfully!"
    echo "Customer ID: $id"
}

# ==========================================
# 2. VIEW CUSTOMERS
# ==========================================

customer_view() {

    echo
    echo "========== CUSTOMER LIST =========="

    if [[ ! -s "$CUSTOMER_DB" ]]; then
        echo "No customers found!"
        return
    fi

    printf "%-12s %-22s %-15s %-30s\n" \
        "ID" "NAME" "PHONE" "EMAIL"

    echo "---------------------------------------------------------------"

    awk -F'|' 'NF==4 {
        printf "%-12s %-22s %-15s %-30s\n",
        $1,$2,$3,$4
    }' "$CUSTOMER_DB"
}

# ==========================================
# 3. SEARCH CUSTOMER
# ==========================================

customer_search() {

    local id

    read -rp "Enter Customer ID: " id

    if ! awk -F'|' -v id="$id" '$1==id {found=1} END {exit !found}' "$CUSTOMER_DB"; then
        echo "Customer not found!"
        return
    fi

    echo
    echo "Customer Details:"

    awk -F'|' -v id="$id" '$1==id {
        print "ID    : " $1
        print "Name  : " $2
        print "Phone : " $3
        print "Email : " $4
    }' "$CUSTOMER_DB"
}

# ==========================================
# 4. UPDATE CUSTOMER
# ==========================================

customer_update() {

    local id choice value temp

    read -rp "Enter Customer ID: " id

    if ! awk -F'|' -v id="$id" '$1==id {found=1} END {exit !found}' "$CUSTOMER_DB"; then
        echo "Customer not found!"
        return
    fi

    echo
    echo "1. Update Name"
    echo "2. Update Phone"
    echo "3. Update Email"

    read -rp "Enter choice: " choice

    case "$choice" in
        1)
            read -rp "Enter new name: " value

            if [[ ! "$value" =~ ^[a-zA-Z][a-zA-Z\ \'-]{1,48}$ ]]; then
                echo "Invalid name!"
                return
            fi
            ;;
        2)
            read -rp "Enter new phone: " value

            if [[ ! "$value" =~ ^[0-9]{10}$ ]]; then
                echo "Invalid phone number!"
                return
            fi
            ;;
        3)
            read -rp "Enter new email: " value

            if [[ ! "$value" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
                echo "Invalid email!"
                return
            fi
            ;;
        *)
            echo "Invalid choice!"
            return
            ;;
    esac

    # Update using temporary file
    temp=$(mktemp) || return 1

    awk -F'|' -v OFS='|' -v id="$id" \
        -v choice="$choice" -v value="$value" '
        $1==id {
            if(choice==1) $2=value
            if(choice==2) $3=value
            if(choice==3) $4=value
        }
        {print}
    ' "$CUSTOMER_DB" > "$temp"

    if mv "$temp" "$CUSTOMER_DB"; then
        echo "Customer updated successfully!"
    else
        rm -f "$temp"
        echo "Update failed!"
    fi
}

# ==========================================
# 5. DELETE CUSTOMER
# ==========================================

customer_delete() {

    local id confirm temp

    read -rp "Enter Customer ID: " id

    if ! awk -F'|' -v id="$id" '$1==id {found=1} END {exit !found}' "$CUSTOMER_DB"; then
        echo "Customer not found!"
        return
    fi

    read -rp "Are you sure you want to delete? (y/n): " confirm

    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo "Deletion cancelled!"
        return
    fi

    temp=$(mktemp) || return 1

    awk -F'|' -v id="$id" '$1!=id {print}' \
        "$CUSTOMER_DB" > "$temp"

    if mv "$temp" "$CUSTOMER_DB"; then
        echo "Customer deleted successfully!"
    else
        rm -f "$temp"
        echo "Deletion failed!"
    fi
}

# ==========================================
# 6. CUSTOMER MENU
# ==========================================

customer_menu() {

    while true
    do
        echo
        echo "===================================="
        echo "       CUSTOMER MANAGEMENT"
        echo "===================================="
        echo "1. Add Customer"
        echo "2. View Customers"
        echo "3. Search Customer"
        echo "4. Update Customer"
        echo "5. Delete Customer"
        echo "6. Back to Main Menu"
        echo "===================================="

        read -rp "Enter your choice: " choice

        case "$choice" in
            1) customer_add ;;
            2) customer_view ;;
            3) customer_search ;;
            4) customer_update ;;
            5) customer_delete ;;
            6) break ;;
            *) echo "Invalid choice!" ;;
        esac
    done
}


