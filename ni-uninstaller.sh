#!/bin/bash
# Improved Native Instruments Uninstaller for macOS
# Version 2.0

# ===== CONFIGURATION =====
# Text styling
BOLD="\033[1m"
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
CYAN="\033[0;36m"
RESET="\033[0m"

# Global variables
USER_HOME=$(eval echo ~$(logname))
REAL_USER=$(logname)
LOG_FILE="${USER_HOME}/Desktop/NI_Uninstall_$(date +%Y-%m-%d_%H-%M-%S).log"
TRASH_COUNT=0
AUTO_MODE=false
VERBOSE=true
VERSION="2.0"

# ===== UTILITY FUNCTIONS =====

# Print colorized message
print_msg() {
  local color=$1
  local msg=$2
  echo -e "${color}${msg}${RESET}"
}

# Log message to log file
log() {
  local msg=$1
  echo "$(date +"%Y-%m-%d %H:%M:%S") - $msg" >> "$LOG_FILE"
}

# Print and log message
print_and_log() {
  local color=$1
  local msg=$2
  print_msg "$color" "$msg"
  log "$msg"
}

# Ask for confirmation (y/n)
confirm() {
  local prompt=$1
  local default=${2:-n}
  
  if [ "$AUTO_MODE" = true ]; then
    return 0
  fi
  
  local choices="y/N"
  if [ "$default" = "y" ]; then
    choices="Y/n"
  fi
  
  print_msg "$YELLOW" "$prompt [$choices]"
  read -r response
  
  case "$response" in
    [yY]*)
      return 0
      ;;
    [nN]*)
      return 1
      ;;
    "")
      [ "$default" = "y" ] && return 0 || return 1
      ;;
    *)
      return 1
      ;;
  esac
}

# Check if a path exists
check_path() {
  [ -e "$1" ]
}

# Get size of a directory
get_size() {
  local path="$1"
  if [ -d "$path" ]; then
    du -sh "$path" 2>/dev/null | cut -f1
  else
    echo "File"
  fi
}

# Move a file to Trash
move_to_trash() {
  local path="$1"
  
  # Try AppleScript move to trash first
  sudo -u "$REAL_USER" osascript -e "tell application \"Finder\" to delete POSIX file \"$path\"" &>/dev/null
  local status=$?
  
  if [ $status -eq 0 ]; then
    TRASH_COUNT=$((TRASH_COUNT + 1))
    return 0
  else
    # Fallback to direct removal
    rm -rf "$path" 2>/dev/null
    status=$?
    if [ $status -eq 0 ]; then
      TRASH_COUNT=$((TRASH_COUNT + 1))
      return 0
    fi
    return 1
  fi
}

# Remove a file with confirmation
remove_file() {
  local path="$1"
  local desc="$2"
  
  if check_path "$path"; then
    # Calculate size for directories
    size=$(get_size "$path")
    size_info=""
    [ -n "$size" ] && size_info=" (Size: $size)"
    
    if [ "$VERBOSE" = true ]; then
      print_msg "$YELLOW" "Found ${desc}: ${path}${size_info}"
    fi
    
    if [ "$AUTO_MODE" = true ] || confirm "Move to Trash?" "y"; then
      if [ "$VERBOSE" = true ]; then
        print_msg "$BLUE" "Moving to Trash..."
      fi
      
      move_to_trash "$path"
      status=$?
      
      if [ $status -eq 0 ]; then
        log "Moved to Trash: $path"
        return 0
      else
        print_and_log "$RED" "Failed to move to Trash: $path"
        return 1
      fi
    else
      print_and_log "$BLUE" "Skipped by user: $path"
      return 1
    fi
  fi
  return 1
}

# Show progress bar
show_progress() {
  local current=$1
  local total=$2
  local prefix=$3
  local width=50
  
  # Calculate percentage and number of filled blocks
  local percentage=$((current * 100 / total))
  local filled=$((current * width / total))
  local empty=$((width - filled))
  
  # Create the progressbar
  local progress=""
  for ((i=0; i<filled; i++)); do
    progress+="▓"
  done
  
  for ((i=0; i<empty; i++)); do
    progress+="░"
  done
  
  # Print the progressbar
  printf "\r${prefix} [${progress}] ${percentage}%% (${current}/${total})"
  
  # Print newline if the progressbar is complete
  if [ "$current" -eq "$total" ]; then
    echo
  fi
}

# ===== MAIN FUNCTIONS =====

# Initialize log file
init_log() {
  echo "Native Instruments Uninstallation Log" > "$LOG_FILE"
  echo "Date: $(date)" >> "$LOG_FILE"
  echo "Product: $exact_product" >> "$LOG_FILE"
  echo "Version: $VERSION" >> "$LOG_FILE"
  echo "----------------------------------------" >> "$LOG_FILE"
}

# Print welcome message
print_welcome() {
  echo -e "${BOLD}${BLUE}Native Instruments Uninstaller v${VERSION} for macOS${RESET}"
  echo -e "${YELLOW}This script will move Native Instruments files to the Trash.${RESET}"
  echo -e "${GREEN}Files can be recovered from the Trash if needed.${RESET}\n"
}

# Check for sudo
check_sudo() {
  if [ "$EUID" -ne 0 ]; then
    print_msg "$RED" "Please run this script with sudo:"
    echo "sudo ./ni-uninstaller.command"
    exit 1
  fi
}

# Get product info from user
get_product_info() {
  print_msg "$BOLD" "Enter the name of the Native Instruments product to uninstall:"
  read -r input_product
  
  # Extract version if present
  version=""
  if [[ "$input_product" =~ ([0-9]+(\.[0-9]+)?) ]]; then
    version="${BASH_REMATCH[1]}"
  fi
  
  # Normalize product name
  product_name=$(echo "$input_product" | sed -E 's/[0-9]+(\.[0-9]+)?([ ]-?[A-Za-z]*)?$//' | xargs)
  product_lower=$(echo "$product_name" | tr '[:upper:]' '[:lower:]')
  
  # Create product patterns with exact versions
  if [ -n "$version" ]; then
    # For products with version numbers
    exact_product="${product_name}${version}"
    exact_product_spaced="${product_name} ${version}"
  else
    # For products without version numbers
    exact_product="${product_name}"
    exact_product_spaced="${product_name}"
  fi
  
  print_msg "$GREEN" "\nWill uninstall: ${BOLD}$exact_product${RESET}"
  
  if ! confirm "\nContinue with uninstallation?" "n"; then
    print_msg "$RED" "Uninstallation canceled."
    exit 0
  fi
}

# Get operation mode from user
get_operation_mode() {
  echo -e "\n${BOLD}${CYAN}Select operation mode:${RESET}"
  echo -e "1. ${GREEN}Interactive${RESET} - Confirm each file removal"
  echo -e "2. ${YELLOW}Automatic${RESET} - Remove all files without confirmation"
  echo -e "3. ${BLUE}Verbose automatic${RESET} - Show all files but remove without confirmation"
  
  local choice
  read -p "Enter your choice [1-3]: " choice
  
  case $choice in
    2)
      AUTO_MODE=true
      VERBOSE=false
      print_msg "$YELLOW" "Automatic mode selected. All files will be removed without confirmation."
      ;;
    3)
      AUTO_MODE=true
      VERBOSE=true
      print_msg "$BLUE" "Verbose automatic mode selected. All files will be shown and removed."
      ;;
    *)
      AUTO_MODE=false
      VERBOSE=true
      print_msg "$GREEN" "Interactive mode selected. You will confirm each file removal."
      ;;
  esac
}

# Check paths for a specific section
check_section_paths() {
  local section_name="$1"
  local paths=("${@:2}")
  local removed_count=0
  local total_paths=${#paths[@]}
  local current=0
  
  if [ "$VERBOSE" = true ]; then
    print_msg "$BOLD$CYAN" "\n=== $section_name ===${RESET}"
  fi
  
  local found_any=false
  
  for path in "${paths[@]}"; do
    current=$((current + 1))
    
    if [ "$VERBOSE" = false ]; then
      show_progress $current $total_paths "Processing $section_name"
    fi
    
    if check_path "$path"; then
      found_any=true
      # Extract the base filename for description
      local desc=$(basename "$path")
      
      if remove_file "$path" "$desc"; then
        removed_count=$((removed_count + 1))
      fi
    fi
  done
  
  if [ "$VERBOSE" = true ] && [ "$found_any" = false ]; then
    print_msg "$BLUE" "No files found in this section"
  fi
  
  if [ "$VERBOSE" = false ]; then
    # Ensure the progress bar is completed
    show_progress $total_paths $total_paths "Processing $section_name"
  fi
  
  return $removed_count
}

# Check external drives for content
check_external_drives() {
  local exact_product="$1"
  local exact_product_spaced="$2"
  local ext_count=0
  
  if [ "$VERBOSE" = true ]; then
    print_msg "$BOLD$CYAN" "\nCHECKING EXTERNAL DRIVES${RESET}"
  fi
  
  if [ -d "/Volumes" ]; then
    local volumes=(/Volumes/*)
    local total_volumes=${#volumes[@]}
    local current=0
    
    for volume in "${volumes[@]}"; do
      current=$((current + 1))
      
      if [ "$VERBOSE" = false ]; then
        show_progress $current $total_volumes "Checking external volumes"
      fi
      
      if [ -d "$volume" ]; then
        ext_paths=(
          "$volume/Native Instruments/$exact_product"
          "$volume/Native Instruments/$exact_product_spaced"
          "$volume/Audio/Native Instruments/$exact_product"
          "$volume/Audio/Native Instruments/$exact_product_spaced"
          "$volume/Music/Native Instruments/$exact_product"
          "$volume/Music/Native Instruments/$exact_product_spaced"
          "$volume/Samples/Native Instruments/$exact_product"
          "$volume/Samples/Native Instruments/$exact_product_spaced"
        )
        
        for ext_path in "${ext_paths[@]}"; do
          if check_path "$ext_path"; then
            desc="external content"
            if remove_file "$ext_path" "$desc"; then
              ext_count=$((ext_count + 1))
            fi
          fi
        done
      fi
    done
    
    if [ "$VERBOSE" = false ]; then
      # Ensure the progress bar is completed
      show_progress $total_volumes $total_volumes "Checking external volumes"
    fi
  fi
  
  return $ext_count
}

# Print summary of operations
print_summary() {
  local summary=("$@")
  local total_removed=$TRASH_COUNT
  
  print_msg "$GREEN$BOLD" "\nUninstallation process completed!${RESET}"
  print_msg "$BOLD$CYAN" "\n=== SUMMARY ===${RESET}"
  
  for item in "${summary[@]}"; do
    echo -e "  $item"
  done
  
  print_msg "$BOLD" "Total items moved to Trash: ${total_removed}"
  print_msg "$RESET" "A log file has been saved to: ${LOG_FILE}"
  
  if [ $total_removed -gt 0 ]; then
    print_msg "$YELLOW" "\nFiles have been moved to the Trash."
    print_msg "$YELLOW" "You can restore them if needed, or empty the Trash to permanently delete them."
  else
    print_msg "$BLUE" "\nNo files were found to uninstall."
  fi
}

# Main uninstallation process
run_uninstallation() {
  local exact_product="$1"
  local exact_product_spaced="$2"
  local summary=()
  
  print_msg "$GREEN$BOLD" "\nStarting uninstallation process...${RESET}"
  
  # Create exact paths to check
  declare -a app_paths=(
    "/Applications/Native Instruments/$exact_product"
    "/Applications/Native Instruments/$exact_product.app"
    "/Applications/Native Instruments/$exact_product_spaced"
    "/Applications/Native Instruments/$exact_product_spaced.app"
    "/Applications/$exact_product.app"
    "/Applications/$exact_product_spaced.app"
  )
  
  declare -a system_lib_paths=(
    # Preferences
    "/Library/Preferences/com.native-instruments.$product_lower.plist"
    "/Library/Preferences/com.native-instruments.$exact_product.plist"
    "/Library/Preferences/com.native-instruments.$exact_product_spaced.plist"
    
    # Application Support
    "/Library/Application Support/Native Instruments/$exact_product"
    "/Library/Application Support/Native Instruments/$exact_product_spaced"
    
    # Audio plugins
    "/Library/Audio/Plug-Ins/Components/$exact_product.component"
    "/Library/Audio/Plug-Ins/Components/$exact_product_spaced.component"
    "/Library/Audio/Plug-Ins/VST/$exact_product.vst"
    "/Library/Audio/Plug-Ins/VST/$exact_product_spaced.vst"
    "/Library/Audio/Plug-Ins/VST3/$exact_product.vst3"
    "/Library/Audio/Plug-Ins/VST3/$exact_product_spaced.vst3"
    "/Library/Audio/Plug-Ins/HAL/$exact_product.plugin"
    "/Library/Audio/Plug-Ins/HAL/$exact_product_spaced.plugin"
    
    # Hardware support
    "/Library/Extensions/NIUSB$exact_product.kext"
    "/Library/Extensions/NIUSB$exact_product_spaced.kext"
  )
  
  declare -a user_lib_paths=(
    # User Preferences
    "$USER_HOME/Library/Preferences/com.native-instruments.$product_lower.plist"
    "$USER_HOME/Library/Preferences/com.native-instruments.$exact_product.plist"
    "$USER_HOME/Library/Preferences/com.native-instruments.$exact_product_spaced.plist"
    
    # User Application Support
    "$USER_HOME/Library/Application Support/Native Instruments/$exact_product"
    "$USER_HOME/Library/Application Support/Native Instruments/$exact_product_spaced"
    
    # User Audio plugins
    "$USER_HOME/Library/Audio/Plug-Ins/Components/$exact_product.component"
    "$USER_HOME/Library/Audio/Plug-Ins/Components/$exact_product_spaced.component"
    "$USER_HOME/Library/Audio/Plug-Ins/VST/$exact_product.vst"
    "$USER_HOME/Library/Audio/Plug-Ins/VST/$exact_product_spaced.vst"
    "$USER_HOME/Library/Audio/Plug-Ins/VST3/$exact_product.vst3"
    "$USER_HOME/Library/Audio/Plug-Ins/VST3/$exact_product_spaced.vst3"
    
    # Caches
    "$USER_HOME/Library/Caches/com.native-instruments.$exact_product"
    "$USER_HOME/Library/Caches/com.native-instruments.$exact_product_spaced"
  )
  
  declare -a registry_paths=(
    # Service Center
    "/Library/Application Support/Native Instruments/Service Center/$exact_product.xml"
    "/Library/Application Support/Native Instruments/Service Center/$exact_product_spaced.xml"
    
    # Installed Products
    "/Users/Shared/Native Instruments/installed_products/$exact_product.json"
    "/Users/Shared/Native Instruments/installed_products/$exact_product_spaced.json"
  )
  
  # 1. Check Applications
  if check_section_paths "CHECKING APPLICATIONS" "${app_paths[@]}"; then
    count=$?
    if [ $count -gt 0 ]; then
      summary+=("${GREEN}✓ Moved $count application files to Trash${RESET}")
    else
      summary+=("${BLUE}○ No application files found${RESET}")
    fi
  fi
  
  # 2. Check System Library
  if check_section_paths "CHECKING SYSTEM LIBRARY LOCATIONS" "${system_lib_paths[@]}"; then
    count=$?
    if [ $count -gt 0 ]; then
      summary+=("${GREEN}✓ Moved $count system library files to Trash${RESET}")
    else
      summary+=("${BLUE}○ No system library files found${RESET}")
    fi
  fi
  
  # 3. Check User Library
  if check_section_paths "CHECKING USER LIBRARY LOCATIONS" "${user_lib_paths[@]}"; then
    count=$?
    if [ $count -gt 0 ]; then
      summary+=("${GREEN}✓ Moved $count user library files to Trash${RESET}")
    else
      summary+=("${BLUE}○ No user library files found${RESET}")
    fi
  fi
  
  # 4. Check Registry
  if check_section_paths "CHECKING PRODUCT REGISTRY" "${registry_paths[@]}"; then
    count=$?
    if [ $count -gt 0 ]; then
      summary+=("${GREEN}✓ Moved $count product registry files to Trash${RESET}")
    else
      summary+=("${BLUE}○ No product registry files found${RESET}")
    fi
  fi
  
  # 5. Check for content libraries
  if confirm "\nDo you want to check for content libraries?" "y"; then
    content_count=0
    
    # Define exact content library paths
    declare -a content_paths=(
      "/Users/Shared/Native Instruments/$exact_product"
      "/Users/Shared/Native Instruments/$exact_product_spaced"
      "$USER_HOME/Documents/Native Instruments/$exact_product"
      "$USER_HOME/Documents/Native Instruments/$exact_product_spaced"
      "$USER_HOME/Music/Native Instruments/$exact_product"
      "$USER_HOME/Music/Native Instruments/$exact_product_spaced"
    )
    
    if check_section_paths "CONTENT LIBRARIES" "${content_paths[@]}"; then
      count=$?
      content_count=$((content_count + count))
    fi
    
    # Check for external drives
    if confirm "\nCheck external drives for content?" "n"; then
      if check_external_drives "$exact_product" "$exact_product_spaced"; then
        ext_count=$?
        if [ $ext_count -gt 0 ]; then
          summary+=("${GREEN}✓ Moved $ext_count files from external drives to Trash${RESET}")
          content_count=$((content_count + ext_count))
        else
          summary+=("${BLUE}○ No content found on external drives${RESET}")
        fi
      fi
    fi
    
    if [ $content_count -gt 0 ]; then
      summary+=("${GREEN}✓ Moved $content_count content library files to Trash${RESET}")
    else
      summary+=("${BLUE}○ No content library files found${RESET}")
    fi
  else
    summary+=("${BLUE}○ Content library check skipped${RESET}")
  fi
  
  print_summary "${summary[@]}"
}

# Main function
main() {
  check_sudo
  print_welcome
  get_product_info
  get_operation_mode
  init_log
  run_uninstallation "$exact_product" "$exact_product_spaced"
  exit 0
}

# Run the main function
main
