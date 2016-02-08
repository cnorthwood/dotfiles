#!/bin/bash

# Based on ~/.osx from https://mths.be/osx (MIT licensed)

read -n 1 -p "Is this machine a BBC one? (y/n) " BBC
echo

for domain in ~/Library/Preferences/ByHost/com.apple.systemuiserver.*; do
	defaults write "${domain}" dontAutoLoad -array \
		"/System/Library/CoreServices/Menu Extras/TimeMachine.menu" \
		"/System/Library/CoreServices/Menu Extras/Volume.menu" \
		"/System/Library/CoreServices/Menu Extras/User.menu"
done
defaults write com.apple.systemuiserver menuExtras -array \
	"/System/Library/CoreServices/Menu Extras/Bluetooth.menu" \
	"/System/Library/CoreServices/Menu Extras/AirPort.menu" \
	"/System/Library/CoreServices/Menu Extras/Battery.menu" \
	"/System/Library/CoreServices/Menu Extras/Clock.menu" \
        "/Applications/Utilities/Keychain Access.app/Contents/Resources/Keychain.menu"

# Position Dock on the left at home due to monitor setup
if [ "$BBC" = "n" ]; then
    defaults write com.apple.dock orientation left
fi

# Don’t group windows by application in Mission Control
# (i.e. use the old Exposé behavior instead)
defaults write com.apple.dock expose-group-by-app -bool false

# Disable Dashboard
defaults write com.apple.dashboard mcx-disabled -bool true

# Don’t show Dashboard as a Space
defaults write com.apple.dock dashboard-in-overlay -bool true

# Get rid of default Dock apps
defaults write com.apple.dock persistent-apps -array

# Don't sleep on AC
sudo /usr/libexec/PlistBuddy /Library/Preferences/SystemConfiguration/com.apple.PowerManagement.plist -c 'Set "Custom Profile:AC Power:System Sleep Timer" 0'

# Expand save panel by default
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true

# Expand print panel by default
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true

# Save to disk (not to iCloud) by default
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

# Automatically quit printer app once the print jobs complete
defaults write com.apple.print.PrintingPrefs "Quit When Finished" -bool true

# Trackpad: enable tap to click for this user and for the login screen
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# Trackpad: map bottom right corner to right-click
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadCornerSecondaryClick -int 2
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadRightClick -bool true
defaults -currentHost write NSGlobalDomain com.apple.trackpad.trackpadCornerClickBehavior -int 1
defaults -currentHost write NSGlobalDomain com.apple.trackpad.enableSecondaryClick -bool true

# Disable “natural” (Lion-style) scrolling
defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false

# Use scroll gesture with the Ctrl (^) modifier key to zoom
defaults write com.apple.universalaccess closeViewScrollWheelToggle -bool true
defaults write com.apple.universalaccess HIDScrollZoomModifierMask -int 262144

# Stop iTunes from responding to the keyboard media keys
launchctl unload -w /System/Library/LaunchAgents/com.apple.rcd.plist 2> /dev/null

# Open new Finder windows at $HOME
defaults write com.apple.finder NewWindowTarget -string "PfHm"

# Use column view
defaults write com.apple.finder FXPreferredViewStyle -string "clmv"

# When performing a search, search the current folder by default
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

# Don't show Tags
defaults write com.apple.finder SidebarTagsSctionDisclosedState 0
# TODO: Customise favourites

# Show the ~/Library directory
chflags nohidden "${HOME}/Library"

# Don't show the ~/bin directory
mkdir -p ~/bin
chflags hidden "${HOME}/bin"

# Enable the Develop menu and the Web Inspector in Safari
defaults write com.apple.Safari IncludeDevelopMenu -bool true
defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled -bool true

# Add a context menu item for showing the Web Inspector in web views
defaults write NSGlobalDomain WebKitDeveloperExtras -bool true

# Copy email addresses as `foo@example.com` instead of `Foo Bar <foo@example.com>` in Mail.app
defaults write com.apple.mail AddressesIncludeNameOnPasteboard -bool false

# Set Terminal to use Pro theme
defaults write com.apple.terminal "Default Window Settings" "Pro"
/usr/libexec/PlistBuddy ~/Library/Preferences/com.apple.Terminal.plist -c 'Set "Window Settings:Pro:rowCount" 40'
/usr/libexec/PlistBuddy ~/Library/Preferences/com.apple.Terminal.plist -c 'Set "Window Settings:Pro:columnCount" 160'
# TBC: Map home/end to Ctrl+A and Ctrl+E

# Prevent Time Machine from prompting to use new hard drives as backup volume
defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true

# Disable local Time Machine backups
hash tmutil &> /dev/null && sudo tmutil disablelocal

# Prevent Photos from opening automatically when devices are plugged in
defaults -currentHost write com.apple.ImageCapture disableHotPlug -bool true

# Ask for password after 5 seconds
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 5

# Screen Saver: Flurry
defaults -currentHost write com.apple.screensaver moduleDict -dict moduleName -string "Flurry" path -string "/System/Library/Screen Savers/Flurry.saver" type -int 0

# Create SSH key
test -f ~/.ssh/id_rsa || (ssh-keygen -t rsa -b 4096 && ssh-add ~/.ssh/id_rsa)

# Set up proxies if this is a BBC machine
if [ "$BBC" = "y" ]; then
    cat >~/.ssh/proxy <<EOF
#!/bin/sh
export NETWORK_LOCATION="\$(/usr/sbin/scselect 2>&1 | egrep '^ \*' | sed 's:.*(\(.*\)):\1:')" 
if [ "\$NETWORK_LOCATION" = "RD_Wired" ]; then
    nc -x "socks-gw.rd.bbc.co.uk" -X 5 \$1 \$2
else
    nc -X 5 \$1 \$2
fi
EOF

    chmod +x ~/.ssh/proxy

    cat >~/.ssh/config <<EOF
ProxyCommand ~/.ssh/proxy %h %p

Host localhost
    ProxyCommand none
EOF

    touch ~/.bash_profile
    grep -q NETWORK_LOCATION ~/.bash_profile || cat >>~/.bash_profile <<EOF
export NETWORK_LOCATION="\$(/usr/sbin/scselect 2>&1 | egrep '^ \*' | sed 's:.*(\(.*\)):\1:')"
if [ "\$NETWORK_LOCATION" = "RD_Wired" ]; then
    export http_proxy="http://www-cache.rd.bbc.co.uk:8080"
    export https_proxy="http://www-cache.rd.bbc.co.uk:8080"
fi
EOF

source ~/.bash_profile

fi

cd ~/Downloads

# Set up Logitech control centre
if [ ! -d "/Applications/Utilities/Logitech Unifying Software.app" ]; then
    echo "Downloading Logitech Control Center..."
    curl -OL http://www.logitech.com/pub/techsupport/mouse/mac/lcc3.9.3.zip
    rm -rf "LCC Installer.app"
    unzip lcc3.9.3.zip
    open "LCC Installer.app"

    read -p "Press Enter to continue" key
fi

/usr/libexec/PlistBuddy ~/Library/Preferences/com.Logitech.Control\ Center.Assignments.registry -c 'Set "Assignments Registry:Actor Properties:Groups:0:Actor Properties:Groups:3:Actor Properties:Action:Actor Identifier" "action.Mission Control"'

# Set up printers
if [ ! -d "/Library/Printers/hp/Utilities/HP Utility.app" ]; then
    curl -LO http://support.apple.com/downloads/DL907/en_US/hpprinterdriver3.1.dmg
    open hpprinterdriver3.1.dmg
    read -p "Press Enter to continue" key
fi

if [ "$BBC" = "y" ]; then
    lpadmin -p "a3c_mcf5" -L "Dock House, 5th Floor" -E -v "lpd://print" -P "/Library/Printers/PPDs/Contents/Resources/HP Color LaserJet CM6040 MFP.gz"
fi

# Set up Homebrew
xcode-select --install
test "`which brew`" = "" && ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

# Set up Git
git config --global user.name "Chris Northwood"
if [ "$BBC" = "y" ]; then
    git config --global core.gitproxy ~/.ssh/proxy
    git config --global user.email "chris.northwood@bbc.co.uk"
else
    git config --global user.email "chris@pling.org.uk"
fi
cat >~/.gitignore <<EOF
*.iml
.idea
.DS_Store
EOF
git config --global core.excludesfile '~/.gitignore'
git config --global alias.newbranch '!sh -c "git checkout -b \$1 && git branch --set-upstream-to origin/master" -'
git config --global alias.cleanup '!sh -c "git branch --merged master | grep -v \"\* master\" | xargs -n 1 git branch -d"'
git config --global pull.rebase true

# Install Dropbox
if [ ! -d "/Applications/Dropbox.app" ]; then
    echo "Installing Dropbox"
    curl -Lo Dropbox.dmg https://www.dropbox.com/download?plat=mac
    open Dropbox.dmg
   ead "Press Enter to continue"
fi

# Install KeepassX
if [ ! -d "/Applications/KeePassX.app" ]; then
    open "https://www.keepassx.org/downloads"
    read -p "Press Enter to continue" key
fi

# If not BBC, install Spideroak
if [ "$BBC" = "n" ] ; then
    if [ ! -d "/Applications/SpiderOak.app" ]; then
        echo "Installing Spideroak"
        curl -Lo Spideroak.dmg https://spideroak.com/getbuild?platform=mac
        open Spideroak.dmg
        read -p "Press Enter to continue" key
    fi

    # TODO: Configure Spideroak
fi

# Install Chrome
if [ ! -d "/Applications/Google Chrome.app" ]; then
    echo "Installing Chrome"
    curl -LO https://www.google.com/chrome?brand=CHMO#eula
    open googlechrome.dmg
    read -p "Press Enter to continue" key
fi

# Install IntelliJ
if [ ! -d "/Applications/IntelliJ IDEA 15.app" ]; then
    open https://www.jetbrains.com/idea/download/
    read -p "Press Enter to continue" key
fi

# Install VirtualBox
if [ ! -d "/Applications/VirtualBox.app" ]; then
    open "https://www.virtualbox.org/wiki/Downloads"
    read -p "Press Enter to continue" key
fi

# Install Vagrant
if [ "`which vagrant`" = "" ]; then
    open "https://www.vagrantup.com/downloads.html"
    read -p "Press Enter to continue" key
fi
vagrant plugin list | grep -q vbguest || vagrant plugin install vagrant-vbguest

# Install Java
test "`which java`" = "" && brew cask install java

# Install DMDirc
if [ ! -d "/Applications/DMDirc.app" ]; then
    open "https://www.dmdirc.com/downloads"
    read -p "Press Enter to continue" key
fi

# If BBC: install Office 365 and Lync 
if [ "$BBC" = "y" ]; then
    open "https://portal.microsoftonline.com/"
    if [ ! -d "/Applications/Microsoft Lync.app" ]; then
        curl -LO https://download.microsoft.com/download/5/0/0/500C7E1F-3235-47D4-BC11-95A71A1BA3ED/lync_14.2.1_150923.dmg
        open lync_14.2.1_150923.dmg
    fi
    read -p "Press Enter to continue" key
fi

# Install Flux
if [ ! -d "/Applications/Flux.app" ]; then
    curl -LO https://justgetflux.com/dlmac.html
    unzip Flux.zip
    open Flux.app
    read -p "Press Enter to continue" key
fi

# From App Store: install Keynote, BetterSnapTool, Xcode, Slack
echo "Now, install apps from the App Store"
open "/Applications/App Store.app"
