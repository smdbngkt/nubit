#!/bin/bash

# Memeriksa apakah skrip dijalankan dengan pengguna root
if [ "$(id -u)" != "0" ]; then
    echo "Skrip ini harus dijalankan dengan hak akses pengguna root."
    echo "Cobalah gunakan perintah 'sudo -i' untuk beralih ke pengguna root, kemudian jalankan skrip ini lagi."
    exit 1
fi

# Memeriksa dan menginstal Node.js dan npm
function install_nodejs_and_npm() {
    if command -v node > /dev/null 2>&1; then
        echo "Node.js sudah terinstal"
    else
        echo "Node.js belum terinstal, sedang menginstal..."
        curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
        sudo apt-get install -y nodejs
    fi

    if command -v npm > /dev/null 2>&1; then
        echo "npm sudah terinstal"
    else
        echo "npm belum terinstal, sedang menginstal..."
        sudo apt-get install -y npm
    fi
}

# Memeriksa dan menginstal PM2
function install_pm2() {
    if command -v pm2 > /dev/null 2>&1; then
        echo "PM2 sudah terinstal"
    else
        echo "PM2 belum terinstal, sedang menginstal..."
        npm install pm2@latest -g
    fi
}

# Fungsi pemasangan node
function install_node() {
    install_nodejs_and_npm
    install_pm2

    echo "Memulai pemasangan node Nubit..."

    while [ $# -gt 0 ]; do
        if [[ $1 = "--"* ]]; then
            v="${1/--/}"
            declare "$v"="$2"
            shift
        fi
        shift
    done

    if [ "$(uname -m)" = "arm64" -a "$(uname -s)" = "Darwin" ]; then
        ARCH_STRING="darwin-arm64"
        MD5_NUBIT="0cd8c1dae993981ce7c5c5d38c048dda"
        MD5_NKEY="4045adc4255466e37d453d7abe92a904"
    elif [ "$(uname -m)" = "x86_64" -a "$(uname -s)" = "Darwin" ]; then
        ARCH_STRING="darwin-x86_64"
        MD5_NUBIT="7ce3adde1d9607aeebdbd44fa4aca850"
        MD5_NKEY="84bff807aa0553e4b1fac5c5e34b01f1"
    elif [ "$(uname -m)" = "aarch64" -o "$(uname -m)" = "arm64" ]; then
        ARCH_STRING="linux-arm64"
        MD5_NUBIT="9de06117b8f63bffb3d6846fac400acf"
        MD5_NKEY="3b890cf7b10e193b7dfcc012b3dde2a3"
    elif [ "$(uname -m)" = "x86_64" ]; then
        ARCH_STRING="linux-x86_64"
        MD5_NUBIT="650608532ccf622fb633acbd0a754686"
        MD5_NKEY="d474f576ad916a3700644c88c4bc4f6c"
    elif [ "$(uname -m)" = "i386" -o "$(uname -m)" = "i686" ]; then
        ARCH_STRING="linux-x86"
        MD5_NUBIT="9e1f66092900044e5fd862296455b8cc"
        MD5_NKEY="7ffb30903066d6de1980081bff021249"
    fi

    if [ -z "$ARCH_STRING" ]; then
        echo "Arsitektur tidak didukung $(uname -s) - $(uname -m)"
        exit 1
    else
        cd $HOME
        FOLDER=nubit-node
        FILE=$FOLDER-$ARCH_STRING.tar
        FILE_NUBIT=$FOLDER/bin/nubit
        FILE_NKEY=$FOLDER/bin/nkey
        if [ -f $FILE ]; then
            rm $FILE
        fi
        OK="N"
        if [ "$(uname -s)" = "Darwin" ]; then
            if [ -d $FOLDER ] && [ -f $FILE_NUBIT ] && [ -f $FILE_NKEY ] && [ $(md5 -q "$FILE_NUBIT" | awk '{print $1}') = $MD5_NUBIT ] && [ $(md5 -q "$FILE_NKEY" | awk '{print $1}') = $MD5_NKEY ]; then
                OK="Y"
            fi
        else
            if ! command -v tar &> /dev/null; then
                echo "Perintah tar tidak tersedia. Silakan instal dan coba lagi"
                exit 1
            fi
            if ! command -v ps &> /dev/null; then
                echo "Perintah ps tidak tersedia. Silakan instal dan coba lagi"
                exit 1
            fi
            if ! command -v bash &> /dev/null; then
                echo "Perintah bash tidak tersedia. Silakan instal dan coba lagi"
                exit 1
            fi
            if ! command -v md5sum &> /dev/null; then
                echo "Perintah md5sum tidak tersedia. Silakan instal dan coba lagi"
                exit 1
            fi
            if ! command -v awk &> /dev/null; then
                echo "Perintah awk tidak tersedia. Silakan instal dan coba lagi"
                exit 1
            fi
            if ! command -v sed &> /dev/null; then
                echo "Perintah sed tidak tersedia. Silakan instal dan coba lagi"
                exit 1
            fi
            if [ -d $FOLDER ] && [ -f $FILE_NUBIT ] && [ -f $FILE_NKEY ] && [ $(md5sum "$FILE_NUBIT" | awk '{print $1}') = $MD5_NUBIT ] && [ $(md5sum "$FILE_NKEY" | awk '{print $1}') = $MD5_NKEY ]; then
                OK="Y"
            fi
        fi
        echo "Memulai node Nubit..."
        if [ $OK = "Y" ]; then
            echo "Pemeriksaan MD5 berhasil. Memulai langsung"
        else
            echo "Pemasangan versi terbaru nubit-node diperlukan untuk memastikan kinerja optimal dan akses ke fitur baru."
            URL=http://nubit.sh/nubit-bin/$FILE
            echo "Memperbarui nubit-node ..."
            echo "Mengunduh dari URL, jangan tutup: $URL"
            if command -v curl >/dev/null 2>&1; then
                curl -sLO $URL
            elif command -v wget >/dev/null 2>&1; then
                wget -qO- $URL
            else
                echo "curl maupun wget tidak tersedia. Silakan instal salah satunya dan coba lagi"
                exit 1
            fi
            tar -xvf $FILE
            if [ ! -d $FOLDER ]; then
                mkdir $FOLDER
            fi
            if [ ! -d $FOLDER/bin ]; then
                mkdir $FOLDER/bin
            fi
            mv $FOLDER-$ARCH_STRING/bin/nubit $FOLDER/bin/nubit
            mv $FOLDER-$ARCH_STRING/bin/nkey $FOLDER/bin/nkey
            rm -rf $FOLDER-$ARCH_STRING
            rm $FILE
            echo "Pembaruan nubit-node selesai."
        fi

        sudo cp $HOME/nubit-node/bin/nubit /usr/local/bin
        sudo cp $HOME/nubit-node/bin/nkey /usr/local/bin
        echo "export store=$HOME/.nubit-light-nubit-alphatestnet-1" >> $HOME/.bash_profile
        
        cat <<EOL > ecosystem.config.js
module.exports = {
  apps: [
    {
      name: "nubit-node",
      script: "./start.sh",
      cwd: "$HOME/nubit-node",
      interpreter: "/bin/bash",
      watch: false,
      env: {
        NODE_ENV: "production"
      },
      error_file: "$HOME/logs/nubit-node-error.log",
      out_file: "$HOME/logs/nubit-node-out.log",
      log_file: "$HOME/logs/nubit-node-combined.log",
      time: true
    }
  ]
};
EOL

        mkdir -p $HOME/logs

        echo "Mengunduh skrip start.sh..."
        curl -sL1 https://nubit.sh/start.sh -o $HOME/nubit-node/start.sh
        chmod +x $HOME/nubit-node/start.sh

        echo "Memulai node nubit dengan PM2..."

        pm2 start ecosystem.config.js --env production
    fi
}

# Memeriksa status layanan Nubit
function check_service_status() {
    pm2 list
}

# Menampilkan log node Nubit
function view_logs() {
    pm2 logs nubit-node
}

# Memeriksa alamat akun
function check_address() {
    nubit state account-address --node.store $store
}

# Memeriksa kunci publik
function check_pubkey() {
    nkey list --p2p.network nubit-alphatestnet-1 --node.type light
}

# Menu utama
function main_menu() {
    while true; do
        clear
        echo "Untuk keluar dari skrip, tekan ctrl c pada keyboard"
        echo "Pilih operasi yang ingin dijalankan:"
        echo "1. Instal node"
        echo "2. Lihat status sinkronisasi node"
        echo "3. Lihat status layanan saat ini"
        echo "4. Lihat alamat dompet"
        echo "5. Lihat pubkey"
        read -p "Masukkan pilihan (1-5): " OPTION

        case $OPTION in
        1) install_node ;;
        2) check_service_status ;;
        3) view_logs ;;
        4) check_address ;;
        5) check_pubkey ;;
        *) echo "Pilihan tidak valid." ;;
        esac
        echo "Tekan sembarang tombol untuk kembali ke menu utama..."
        read -n 1
    done
}

# Menampilkan menu utama
main_menu
