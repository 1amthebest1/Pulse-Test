#!/bin/bash

# Function to install Go
install_go() {
    echo "[INFO] Starting the installation of Go..."

    sudo rm -rf /usr/local/go
    go_url="https://dl.google.com/go/go1.21.0.linux-amd64.tar.gz"
    go_file="go1.21.0.linux-amd64.tar.gz"

    echo "[INFO] Downloading Go from $go_url..."
    wget "$go_url" -O "$go_file"

    echo "[INFO] Extracting Go to /usr/local..."
    sudo tar -C /usr/local -xzf "$go_file"

    echo "[INFO] Updating PATH to include Go..."
    echo "export PATH=/usr/local/go/bin:\$PATH" >> ~/.bashrc
    echo "export GOPATH=\$HOME/go" >> ~/.bashrc
    echo "export PATH=\$PATH:\$GOPATH/bin" >> ~/.bashrc

    # Update the current shell environment
    export PATH=/usr/local/go/bin:$PATH
    export GOPATH=$HOME/go

    echo "[INFO] Go installation completed and PATH updated."
}

# Function to check Go version
check_go_version() {
    # Use the absolute path to Go if it's installed
    if [ -x "/usr/local/go/bin/go" ]; then
        go_version=$(/usr/local/go/bin/go version | grep -oP '(?<=go)([0-9]+\.[0-9]+)')
        required_version="1.21"

        if [ "$(printf '%s\n' "$required_version" "$go_version" | sort -V | head -n1)" != "$required_version" ]; then
            echo "[ERROR] Go version $go_version is outdated. Installing Go $required_version..."
            install_go
        else
            echo "[INFO] Go version $go_version is up to date."
        fi
    else
        echo "[ERROR] Go is not installed. Installing Go $required_version..."
        install_go
    fi
}

# Call the Go version check function
check_go_version

# Function to install ffuf
install_ffuf() {
    ffuf_bin="./ffuf/ffuf"

    # Check if ffuf is already installed
    if [ ! -f "$ffuf_bin" ]; then
        echo "[INFO] Installing ffuf..."

        git clone https://github.com/ffuf/ffuf
        cd ffuf
        go get
        go build
        cd ..
    else
        echo "[INFO] ffuf is already installed."
    fi
}

# Function to run ffuf
run_ffuf() {
    read -p "[PROMPT] Enter the target domain (e.g., target.com): " target_domain

    echo "[INFO] Running ffuf on target domain: $target_domain"
    output_file=~/Desktop/ffuf_subs

    ./ffuf/ffuf -w /usr/share/wordlists/dirb/common.txt -u http://$target_domain/ -H "Host: FUZZ.$target_domain" -mc 200 -o "$output_file"

    echo "[INFO] ffuf run completed. Results saved to $output_file."
}

# Function to download and install gospider
download_and_install_gospider() {
    clone_dir="gospider"
    repo_url="https://github.com/jaeles-project/gospider.git"
    gospider_bin="/usr/local/bin/gospider"

    if [ ! -f "$gospider_bin" ]; then
        echo "[INFO] gospider is not installed. Installing it now..."

        if [ -d "$clone_dir" ]; then
            echo "[INFO] Directory $clone_dir already exists. Skipping clone."
        else
            echo "[INFO] Cloning gospider repository from $repo_url..."
            git clone "$repo_url" "$clone_dir"
        fi

        echo "[INFO] Building gospider in directory $clone_dir..."
        cd "$clone_dir"
        go build -o gospider

        echo "[INFO] Moving gospider to /usr/local/bin and setting executable permissions..."
        sudo mv gospider "$gospider_bin"
        sudo chmod +x "$gospider_bin"
        cd ..
    else
        echo "[INFO] gospider is already installed."
    fi
}

# Function to run gospider with verbose output
run_gospider() {
    target_file="$1"
    echo "[INFO] Running gospider on the target file: $target_file"
    gospider_output_dir="output"
    gospider_log_file="gospider_verbose.log"

    gospider -S "$target_file" -o "$gospider_output_dir" -c 10 -d 0 -k 1 --timeout 5 --other-source --include-subs | tee "$gospider_log_file"
    echo "[INFO] gospider run completed."
}

# Function to strip HTTP protocol from URLs
strip_protocol() {
    input_file="$1"
    output_file="$2"

    echo "[INFO] Stripping HTTP protocol from $input_file..."
    grep -oP '(?<=://).*' "$input_file" > "$output_file"
    echo "[INFO] Stripped URLs saved to $output_file."
}

# Function to install and run subfinder
install_and_run_subfinder() {
    target_file="$1"
    subfinder_bin="./subfinder/v2/cmd/subfinder/subfinder"

    if [ ! -f "$subfinder_bin" ]; then
        echo "[INFO] Installing subfinder..."
        if [ ! -d "subfinder" ]; then
            echo "[INFO] Cloning subfinder repository..."
            git clone https://github.com/projectdiscovery/subfinder.git
        fi
        cd subfinder/v2/cmd/subfinder
        go build
        cd ../../../
    else
        echo "[INFO] Subfinder is already installed."
    fi

    echo "[INFO] Running subfinder on the target file: $target_file"
    output_dir=~/Desktop/output
    mkdir -p "$output_dir"
    output_file="$output_dir/subfinder.txt"
    "$subfinder_bin" -active -dL "$target_file" -o "$output_file"
    echo "[INFO] subfinder run completed. Results saved to $output_file."
}

# Function to install and run amass
install_and_run_amass() {
    target_file="$1"
    amass_bin="./amass/amass"
    stripped_file="/home/user/Desktop/urls_stripped.txt"

    strip_protocol "$target_file" "$stripped_file"

    if [ ! -f "$amass_bin" ]; then
        echo "[INFO] Installing amass..."
        if [ ! -d "amass" ]; then
            echo "[INFO] Cloning amass repository..."
            git clone https://github.com/owasp-amass/amass.git
        fi
        cd amass
        go build ./cmd/amass
        cd ..
    else
        echo "[INFO] Amass is already installed."
    fi

    echo "[INFO] Running amass on the target file: $stripped_file"
    output_file=~/Desktop/amass.txt
    "$amass_bin" enum -df "$stripped_file" -p 443,80,8080 -active -o "$output_file"
    echo "[INFO] amass run completed. Results saved to $output_file."
}

# Function to run pulse
run_pulse() {
  echo "Enter path to input file for ffuf:"
  read ffuf_input_file
  echo "Enter output file for ffuf results:"
  read ffuf_output_file

  ./ffuf -w "$ffuf_input_file" -u FUZZ -mc 200 -of md -o temp_output.md
  grep -Eo 'https?://[^ ]+' temp_output.md | sort -u >> "$ffuf_output_file"
  rm temp_output.md
}

# Function to install xml_extractor
install_xml_extractor() {
    xml_extractor_dir="xml-url-extractor"

    # Check if xml_extractor is already installed
    if [ ! -d "$xml_extractor_dir" ]; then
        echo "[INFO] Installing xml_extractor..."
        git clone https://github.com/1amthebest1/xml-url-extractor.git
        chmod +x "$xml_extractor_dir"
    else
        echo "[INFO] xml_extractor is already installed."
    fi
}

# Function to run xml_extractor
run_xml_extractor() {
    install_xml_extractor
    read -p "[PROMPT] Enter the XML file path or sitemap URL: " xml_input
    cd xml-url-extractor
    chmod +x script.sh
    echo "[INFO] Running xml_extractor..."
    
    ./script.sh "$xml_input"

    echo "[INFO] xml_extractor run completed."
    cd ..
}

# Function to install and run URL-extractor
install_and_run_url_extractor() {
    url_extractor_bin="./URL-extractor/script.sh"

    # Check if URL-extractor is already installed
    if [ ! -f "$url_extractor_bin" ]; then
        echo "[INFO] Installing URL-extractor..."
        git clone https://github.com/1amthebest1/URL-extractor.git
        cd URL-extractor
        chmod +x script.sh
        cd ..
    else
        echo "[INFO] URL-extractor is already installed."
    fi

    read -p "[PROMPT] Enter the file to extract URLs from: " file_to_extract
    read -p "[PROMPT] Enter the domain or file containing domains to extract: " domain_to_extract

    echo "[INFO] Running URL-extractor..."
    ./URL-extractor/script.sh "$file_to_extract" "$domain_to_extract"

    echo "[INFO] URL-extractor run completed."
}

# Main script
target_file="$1"

if [ ! -f "$target_file" ]; then
    echo "[ERROR] The specified file does not exist: $target_file"
    exit 1
fi

if ! command -v go &> /dev/null; then
    read -p "[PROMPT] Do you want to install Go? (yes/no): " install_go_choice
    if [ "$install_go_choice" == "yes" ]; then
        install_go
    else
        echo "[INFO] Skipping Go installation."
        exit 1
    fi
else
    check_go_version
fi

read -p "[PROMPT] Do you want to install gospider? (yes/no): " install_gospider_choice
if [ "$install_gospider_choice" == "yes" ]; then
    download_and_install_gospider
fi

# Main loop
while true; do
    read -p "[PROMPT] Do you want to run gospider, subfinder, amass, ffuf, xml_extractor, URL-extractor, or exit (g/s/a/f/x/u/e): " tool_choice

    if [ "$tool_choice" == "g" ]; then
        run_gospider "$target_file"
    elif [ "$tool_choice" == "s" ]; then
        install_and_run_subfinder "$target_file"
    elif [ "$tool_choice" == "a" ]; then
        install_and_run_amass "$target_file"
    elif [ "$tool_choice" == "f" ]; then
        install_ffuf
        run_ffuf
    elif [ "$tool_choice" == "x" ]; then
        install_ffuf 
        run_xml_extractor
    elif [ "$tool_choice" == "p" ]; then
        run_pulse
    elif [ "$tool_choice" == "u" ]; then
        install_and_run_url_extractor
    elif [ "$tool_choice" == "e" ]; then
        echo "[INFO] Exiting the script."
        break
    else
        echo "[ERROR] Invalid choice. Please enter g, s, a, f, x, u, or e."
    fi
done
