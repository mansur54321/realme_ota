#!/bin/bash

# 🎨 Colors for output
  RED="\e[31m";
  GREEN="\e[32m";
  PURPLE="\e[35m";
  YELLOW="\e[33m";
  BLUE="\e[34m";
  RESET="\e[0m"

# 📌 Regions, versions, and servers
declare -A REGIONS=(
    [A4]="APC Global 10100100"
    [A5]="OCA Oce_Cen_Australia 10100101"
    [A6]="MEA Middle_East_Africa 10100110"
    [A7]="ROW Global 10100111"
    [1A]="TW Taiwan 00011010"
    [1B]="IN India 00011011"
    [2C]="SG Singapure 00101100"
    [3C]="VN Vietnam 00111100"
    [3E]="PH Philippines 00111110"
    [33]="ID Indonesia 00110011"
    [37]="RU Russia 00110111"
    [38]="MY Malaysia 00111000"
    [39]="TH Thailand 00111001"
    [44]="EUEX Europe 01000100"
    [51]="TR Turkey 01010001"
    [75]="EG Egypt 01110101"
    [82]="HK Hong_Kong 10000010"
    [83]="SA Saudi_Arabia 10000011"
    [9A]="LATAM Latin_America 10011010"
    [97]="CN China 10010111"
)
declare -A VERSIONS=(
  [A]="Launch version"
  [C]="First update"
  [F]="Second update"
  [H]="Third update"
)
declare -A SERVERS=(
  [97]="-r 1"
  [44]="-r 0"
  [51]="-r 0"
)

# 📌 Function to process OTA
run_ota() {
    region_data=(${REGIONS[$region]})
    region_code=${region_data[0]}
    region_name=${region_data[1]}
    nv_id=${region_data[2]}
    server="${SERVERS[$region]:--r 3}"
    ota_model="$device_model"
    # Remove regional suffixes from the model for the OTA request
    for rm in TR RU EEA T2 CN IN ID MY TH EU; do
        ota_model="${ota_model//$rm/}";
    done

    echo -e "\n🛠 Model: ${COLOR}$device_model${RESET}"
    echo -e "🛠 Region: ${GREEN}$region_name${RESET} (code: ${YELLOW}$region_code${RESET})"
    echo -e "🛠 OTA version: ${BLUE}${VERSIONS[$version]}${RESET}"
    echo -e "🛠 Server: ${GREEN}$server${RESET}"

    # We call Python directly as a module (-m), which is much more reliable
    export PYTHONUTF8=1
    ota_command="python -m realme_ota.main $server $device_model ${ota_model}_11.${version}.01_0001_100001010000 6 $nv_id"
    
    echo -e "🔍 Running: ${BLUE}$ota_command${RESET}"
    output=$(eval "$ota_command")

    # If there is no output, then nothing was found
    if [[ -z "$output" ]]; then
        echo -e "${RED}❌ OTA not found. Check if the model, region, and version are correct.${RESET}"
        return
    fi

    real_ota_version=$(echo "$output" | grep -o '"realOtaVersion": *"[^"]*"' | cut -d '"' -f4)
    real_version_name=$(echo "$output" | grep -o '"realVersionName": *"[^"]*"' | cut -d '"' -f4)
    ota_f_version=$(echo "$real_ota_version" | grep -oE '_11\.[A-Z]\.[0-9]+' | sed 's/_11\.//')
    ota_date=$(echo "$real_ota_version" | grep -oE '_[0-9]{12}$' | tr -d '_')
    ota_version_full="${ota_model}_11.${ota_f_version}_${region_code}_${ota_date}"
    os_version=$(echo "$output" | grep -o '"realOsVersion": *"[^"]*"' | cut -d '"' -f4)
    security_os=$(echo "$output" | grep -o '"securityPatchVendor": *"[^"]*"' | cut -d '"' -f4)
    android_version=$(echo "$output" | grep -o '"androidVersion": *"[^"]*"' | cut -d '"' -f4)
    about_update_url=$(echo "$output" | grep -oP '"panelUrl"\s*:\s*"\K[^"]+')
    version_type_id=$(echo "$output" | grep -oP '"versionTypeId"\s*:\s*"\K[^"]+')

    # Print information
    echo -e "ℹ️   OTA version: ${YELLOW}$real_ota_version${RESET}"
    echo -e "ℹ️   Firmware Version: ${PURPLE}$real_version_name${RESET}"
    echo -e "ℹ️   Android Version: ${YELLOW}$android_version${RESET}"
    echo -e "ℹ️   OS Version: ${YELLOW}$os_version${RESET}"
    echo -e "ℹ️   Security Patch: ${YELLOW}$security_os${RESET}"
    echo -e "ℹ️   Changelog URL: ${GREEN}$about_update_url${RESET}"
    echo -e "ℹ️   OTA Status: ${BLUE}$version_type_id${RESET}"

    download_link=$(echo "$output" | grep -o 'http[s]*://[^"]*' | head -n 1 | sed 's/["\r\n]*$//')
    modified_link=$(echo "$download_link" | sed 's/componentotacostmanual/opexcostmanual/g')

    echo -e "\n📥 OTA version: ${BLUE}$ota_version_full${RESET}"
    if [[ -n "$modified_link" ]]; then
        echo -e "📥 Download URL: ${GREEN}$modified_link${RESET}"
    else
        echo -e "❌ Download URL not found."
    fi

    echo "$ota_version_full" >> "ota_${device_model}.txt"
    echo "$modified_link" >> "ota_${device_model}.txt"
    echo "" >> "ota_${device_model}.txt"

    [[ ! -f Ota_links.csv ]] && echo "OTA Version,URL" > Ota_links.csv
    grep -qF "$modified_link" Ota_links.csv || echo "$ota_version_full,$modified_link" >> Ota_links.csv
}

# 📌 Model and prefix selection
clear
echo -e "${GREEN}+===================================================================================================================+${RESET}"
echo -e "${GREEN}|======${RESET}      ${BLUE}Universal${RESET}    ${BLUE}OTA Finder${RESET}            ${YELLOW}Realme${RESET}   ${GREEN}OPPO${RESET}  ${RED} OnePlus${RESET}             ${BLUE}by ${RESET}${PURPLE}Stano36 & SeRViP${RESET}       ${GREEN}======|${RESET}"
echo -e "${GREEN}+===================================================================================================================+${RESET}"
printf "| %-5s | %-6s | %-18s || %-5s | %-6s | %-18s || %-5s | %-6s | %-18s |\n" "Manif" "R code" "Region" "Manif" "R code" "Region" "Manif" "R code" "Region"
echo -e "+-------------------------------------------------------------------------------------------------------------------+"

keys=("${!REGIONS[@]}"); length=${#keys[@]}
for ((i = 0; i < length; i+=3)); do
    key1="${keys[$i]}"; region_data1=(${REGIONS[$key1]}); region_code1=${region_data1[0]}; region_name1=${region_data1[1]}
    if (( i+1 < length )); then key2="${keys[$i+1]}"; region_data2=(${REGIONS[$key2]}); region_code2=${region_data2[0]}; region_name2=${region_data2[1]}; else key2=""; region_code2=""; region_name2=""; fi
    if (( i+2 < length )); then key3="${keys[$i+2]}"; region_data3=(${REGIONS[$key3]}); region_code3=${region_data3[0]}; region_name3=${region_data3[1]}; else key3=""; region_code3=""; region_name3=""; fi
    printf "|  ${YELLOW}%-4s${RESET} | %-6s | %-18s ||  ${YELLOW}%-4s${RESET} | %-6s | %-18s ||  ${YELLOW}%-4s${RESET} | %-6s | %-18s |\n" "$key1" "$region_code1" "$region_name1" "$key2" "$region_code2" "$region_name2" "$key3" "$region_code3" "$region_name3"
done

echo -e "+-------------------------------------------------------------------------------------------------------------------+"
echo -e "${GREEN}|======  ${RESET}" "OTA version :  ${BLUE}A${RESET} = Launch version ,   ${BLUE}C${RESET} = First update ,   ${BLUE}F${RESET} = Second update ,   ${BLUE}H${RESET} = Third update "    "${GREEN}=======|${RESET}"
echo -e "${GREEN}+===================================================================================================================+${RESET}"

# Prefix list
echo -e "📦 Choose model prefix:  ${YELLOW}1) CPH${RESET},  ${GREEN}2) RMX${RESET},  ${BLUE}3) Custom${RESET},  ${PURPLE}4) Selected${RESET}"
read -p "💡 Select an option (1/2/3/4): " choice

if [[ "$choice" == "4" ]]; then
    if [[ ! -f "devices.txt" ]]; then echo -e "❌ File 'devices.txt' not found. Please create it."; exit 1; fi
    echo -e "\n📱 ${PURPLE}Selected device list:${RESET}";
    echo -e "${GREEN}+====================================================================================================================+${RESET}"
    printf "| %-2s | %-18s | %-14s | %-6s | %-3s || %-2s | %-18s | %-14s | %-6s | %-3s |\n" "No" "Device" "Model" "Manif" "OTA" "No" "Device" "Model" "Manif" "OTA"
    echo -e "+----+--------------------+----------------+--------+-----||----+--------------------+----------------+--------+-----+"
    mapfile -t devices < <(cat devices.txt); total=${#devices[@]}; half=$(( (total + 1) / 2 ))
    for ((i = 0; i < half; i++)); do
        IFS='|' read -r d1 m1 r1 v1 <<< "${devices[$i]}"; if (( i + half < total )); then IFS='|' read -r d2 m2 r2 v2 <<< "${devices[$((i + half))]}"; else d2=""; m2=""; r2=""; v2=""; fi
        printf "| ${YELLOW}%-2d${RESET} | %-18s | %-14s | %-6s | %-3s || ${YELLOW}%-2d${RESET} | %-18s | %-14s | %-6s | %-3s |\n" $((i+1)) "$d1" "$m1" "$r1" "$v1" $((i+1+half)) "$d2" "$m2" "$r2" "$v2"
    done
    echo -e "${GREEN}+====================================================================================================================+${RESET}"
    read -p "🔢 Select device number: " selected
    if ! [[ "$selected" =~ ^[0-9]+$ ]] || (( selected < 1 || selected > total )); then echo "❌ Invalid selection."; exit 1; fi
    IFS='|' read -r selected_name selected_model region version <<< "${devices[$((selected-1))]}"
    device_model="$(echo $selected_model | xargs)"; region="$(echo $region | xargs)"; version="$(echo $version | xargs)"
    echo -e "✅ Selected device: ${PURPLE}$selected_name${RESET}  →  ${BLUE}$device_model${RESET}, ${GREEN}$region${RESET}, ${YELLOW}$version${RESET}"
    if [[ "$device_model" == CPH* ]]; then COLOR=$YELLOW; elif [[ "$device_model" == RMX* ]]; then COLOR=$GREEN; else COLOR=$BLUE; fi
else
    if [[ "$choice" == "1" ]]; then COLOR=$YELLOW; prefix="CPH"; elif [[ "$choice" == "2" ]]; then COLOR=$GREEN; prefix="RMX";
    elif [[ "$choice" == "3" ]]; then COLOR=$BLUE; read -p "🧩 Enter your custom prefix (e.g. XYZ): " prefix; if [[ -z "$prefix" ]]; then echo "❌ Prefix cannot be empty."; exit 1; fi
    else echo "❌ Invalid choice."; exit 1; fi
    echo -e "${COLOR}➡️  You selected option $choice${RESET}"; read -p "🔢 Enter model number: " model_number; device_model="${prefix}${model_number}"
    echo -e "✅ Selected model: ${COLOR}$device_model${RESET}"; read -p "📌 Manifest + OTA version (e.g., 44F): " input
    region="${input:0:${#input}-1}"; version="${input: -1}"; if [[ -z "${REGIONS[$region]}" || -z "${VERSIONS[$version]}" ]]; then echo -e "❌ Invalid input! Exiting."; exit 1; fi
fi

# ✅ Call the OTA function
run_ota

# 🔁 Loop for next choices
while true; do
    echo -e "\n🔄 1 - Change only region/version"
    echo -e "🔄 2 - Change device model (restarts script)"
    echo -e "🔄 3 - Show links list (Ota_links.csv)"
    echo -e "❌ 0 - End script"
    read -p "💡 Select an option (1/2/3/0): " option
    case "$option" in
        1)
            read -p "📌 Manifest + OTA version (e.g., 44F): " input; region="${input:0:${#input}-1}"; version="${input: -1}"
            if [[ -z "${REGIONS[$region]}" || -z "${VERSIONS[$version]}" ]]; then echo "❌ Invalid input."; continue; fi
            run_ota
            ;;
        2) bash "$0"; exit 0 ;;
        3) if [[ -f "Ota_links.csv" ]]; then echo -e "\n--- Contents of Ota_links.csv ---"; cat Ota_links.csv; echo -e "-----------------------------------\n"; else echo -e "❌ File 'Ota_links.csv' has not been created yet."; fi ;;
        0) echo -e "👋 Goodbye."; exit 0 ;;
        *) echo "❌ Invalid option." ;;
    esac
done
