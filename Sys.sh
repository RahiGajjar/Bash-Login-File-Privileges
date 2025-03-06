#!/bin/bash

PASSWORDS_FILE="hashed_passwords.txt"
NON_CRITICAL="noncritical.txt"
TOP_SECRET="topsecret.txt"
ACCESS_CODE="GRANT"  # Code to access topsecret.txt
SECURE_CODE="PSWD"   # Secure code to access the hashed_passwords.txt
USER="rdgajjar"
ACTIVITY_LOG="activity_log.txt"  # Log file to track activities

# Function to log activities
log_activity() {
  echo "$(date): $1" >> "$ACTIVITY_LOG"
}

# Function to hash passwords with SHA256
hash_password() {
  echo -n "$1" | sha256sum | awk '{print $1}'
}

# Function to create a new user
create_user() {
  echo "Enter a new username:"
  read username
  echo "Enter a password for $username:"
  read -s password
  echo "Re-enter the password for verification:"
  read -s re_password
  
  # Verify the passwords match
  if [ "$password" != "$re_password" ]; then
    echo "Passwords do not match. Try again."
    log_activity "Failed account creation attempt for $username. Passwords did not match."
    return
  fi
  
  # Hash the password
  hashed_password=$(hash_password "$password")

  # Save the username and hashed password to the hashed passwords file
  echo "$username $hashed_password" >> "$PASSWORDS_FILE"

  # Grant rwx permission to noncritical.txt
  chmod 777 "$NON_CRITICAL"
  echo "Account created successfully. You now have rwx access to $NON_CRITICAL. Please login again to view file and other options.."

  # Inform the user about accessing topsecret.txt
  echo "If you want access to the 'topsecret.txt' file, please ask $USER for the access code."
  log_activity "Account created for $username."
}

# Function to log in
login_user() {
  echo "Enter your username:"
  read username
  echo "Enter your password:"
  read -s password

 # Hash the entered password
  hashed_password=$(hash_password "$password")
  
  # Check if the username and hashed password match any entry in the passwords file
  user_found=$(grep -E "^$username $hashed_password" "$PASSWORDS_FILE")
  
  if [ -z "$user_found" ]; then
    echo "Invalid username or password. Access denied."
    log_activity "Failed login attempt for $username."
    return
  fi

  echo "Login successful."
  log_activity "$username logged in."

  # Main menu loop
  while true; do
    echo "What would you like to do?"
    echo "1. View 'noncritical.txt'"
    echo "2. Attempt to view 'topsecret.txt'"
    echo "3. View hashed password file (requires secure code)"
    echo "4. View activity log"
    echo "5. Exit"
    read choice

    case $choice in
      1)
        # Display contents of noncritical.txt
        echo "Displaying noncritical.txt:"
        cat "$NON_CRITICAL"
        log_activity "$username viewed 'noncritical.txt'."
        ;;
      2)
        # Ask for the access code to view topsecret.txt
        echo "Enter the access code to view 'topsecret.txt':"
        read access_code
        if [ "$access_code" == "$ACCESS_CODE" ]; then
          echo "Access granted. Displaying 'topsecret.txt':"
          cat "$TOP_SECRET"
          log_activity "$username viewed 'topsecret.txt'."
        else
          echo "Incorrect access code. Access to 'topsecret.txt' denied."
          log_activity "$username failed to access 'topsecret.txt'. Incorrect access code."
        fi
        ;;
      3)
        # Ask for the secure code to view the hashed password file
        echo "Enter the secure code to view the password file:"
        read secure_code
        if [ "$secure_code" == "$SECURE_CODE" ]; then
          echo "Access granted. Displaying hashed password file:"
          cat "$PASSWORDS_FILE"
          log_activity "$username viewed hashed password file."
        else
          echo "Incorrect secure code. Access denied."
          log_activity "$username failed to view hashed password file. Incorrect secure code."
 fi
        ;;
      4)
        # View the activity log
        echo "Displaying activity log:"
        cat "$ACTIVITY_LOG"
        ;;
      5)
        echo "Exiting. Goodbye."
        break  # Break out of the menu and log out
        ;;
      *)
        echo "Invalid option. Please choose again."
        ;;
    esac
  done
}

# Main script menu loop
while true; do
  echo "Welcome! Do you want to (1) Login or (2) Create an Account?"
  read choice

  log_activity "Script started."

  if [ "$choice" -eq 1 ]; then
    login_user
  elif [ "$choice" -eq 2 ]; then
    create_user
  else
    echo "Invalid choice."
    log_activity "Invalid choice entered."
  fi

  # Ask again after completing an action
  echo "Do you want to perform another action? (y/n)"
  read repeat_choice
  if [ "$repeat_choice" != "y" ]; then
    echo "Exiting. Goodbye."
    break  # Exit the loop
  fi
done
