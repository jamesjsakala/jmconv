# jmconv
A Quick Bash Script to Convert Songs to To AAC format Quickly


# Installation
    apt install libid3-tools eyed3 mp3info libmp3-tag-perl  mediainfo -y

    mkdir -p ~/Music/JMCONV
    mkdir  ~/.bin/jmconv/
    cp -vf  config  ~/.bin/jmconv/.config
    cp -vf  jmconv.sh   ~/.bin/jmconv.sh
    chmod +x  ~/.bin/jmconv.sh

    echo 'PATH="$PATH:~/.bin"' >> ~/.bashrc

# Converting a song to aac (Apple Audio)
    jmconv.sh  Tracy Chapman-Baby Can I Hold You.mp3

    
# Converting a list of songs in a playlist(m3u) to aac (Apple Audio)
    jmconv.sh  my_Favorite_Songs.m3u
    

# Converted Files Localtion
    ~/Music/JMCONV
