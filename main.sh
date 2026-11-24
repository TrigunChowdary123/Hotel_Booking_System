
#!/bin/bash

source modules/room_management.sh
source modules/customer_management.sh
source modules/booking_management.sh
source modules/billings.sh
source modules/reports.sh

# Main menu
while true
do
    
    echo "HOTEL BOOKING SYSTEM"
    echo "1.Room Management"
    echo "2.Customer Management"
    echo "3.Booking Management"
    echo "4.Billing and Invoices"
    echo "5.Reports"
    echo "6.Exit"


    read -rp "Enter your choice: " choice

    case $choice in
        1)
            room_menu
            ;;
        2)
            customer_menu
            ;;
        3)
            booking_menu
            ;;
        4)
            billing_menu
            ;;
        5)
            reports_menu
            ;;
        6)
            echo "Thank you for using Hotel Booking System!"
            exit 0
            ;;
        *)
            echo "Invalid choice!Please enter 1-6."
            ;;
    esac

done

