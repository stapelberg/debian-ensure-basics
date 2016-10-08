#!/bin/bash
# vim:ts=4:sw=4:expandtab
# © 2012 Michael Stapelberg (see also: LICENSE)
#
# wget -qO- d.zekjur.net|bash -s

echo "*** debian-ensure-basics"

################################################################################
# Ensure the following locales are present:
# en_DK.UTF-8 (ISO 8601 date/time format)
# de_DE.UTF-8 (everything else, except LC_MESSAGES)
################################################################################

CURRENT_LOCALES=$(grep '^[^#].' /etc/locale.gen)
REGEN_LOCALES=0
for locale in en_DK de_DE
do
    if ! echo "$CURRENT_LOCALES" | grep -q "^$locale.UTF-8 UTF-8$"
    then
        echo "*** Adding locale $locale.UTF-8..."
        echo "$locale.UTF-8 UTF-8" >> /etc/locale.gen
        REGEN_LOCALES=1
    fi
done

[ $REGEN_LOCALES -eq 1 ] && locale-gen

################################################################################
# Ensure the following apt settings are present:
# APT::Install-Recommends "false";
# APT::Install-Suggests "false";
# Acquire::Pdiffs "no";
# Acquire::CompressionTypes::Order:: "gz";
################################################################################

# Ensure this directory exists, we might need to use it.
mkdir -p /etc/apt/apt.conf.d
MATCHING_LINES=$(apt-config dump | grep '^APT::Install-\(Recommends\|Suggests\) "false";$' | wc -l)
if [ "$MATCHING_LINES" -ne 2 ]
then
    echo "*** Setting APT::Install-Recommends and APT::Install-Suggests to false..."
    echo 'APT::Install-Recommends "false";' > /etc/apt/apt.conf.d/99disable-recommends
    echo 'APT::Install-Suggests "false";' > /etc/apt/apt.conf.d/99disable-suggests
fi

if ! apt-config dump | grep -q '^Acquire::Pdiffs "no";$'
then
    echo "*** Disabling APT Pdiffs..."
    echo 'Acquire::Pdiffs "no";' > /etc/apt/apt.conf.d/99disable-pdiffs
fi

if apt-config dump | grep -v '^Acquire::Languages:: "none";$' | grep -q '^Acquire::Languages:: "'
then
    echo 'Acquire::Languages "none";' > /etc/apt/apt.conf.d/99translations
fi

if ! apt-config dump | grep -q '^Acquire::CompressionTypes::Order:: "gz";$'
then
    echo 'Acquire::CompressionTypes::Order { "gz"; };' > /etc/apt/apt.conf.d/99use-gzip
fi

################################################################################
# Ensure the following packages are installed:
# zsh, vim, sudo, less, git
################################################################################
for package in zsh vim sudo less git
do
    if ! dpkg -s "$package" >/dev/null
    then
        echo "*** Installing $package..."
        DEBIAN_FRONTEND=noninteractive \
        DEBCONF_NONINTERACTIVE_SEEN=true \
        LC_ALL=C \
        LANGUAGE=C \
        LANG=C \
            apt-get --force-yes -y install "$package"
    fi
done

################################################################################
# Ensure zsh is the login shell (if it could be installed).
################################################################################

ZSH=$(which zsh)
if [ $? -eq 0 ]
then
    if [ "$SHELL" != "$ZSH" ]
    then
        echo "*** Making zsh the login shell"
        chsh -s "$ZSH"
    fi
fi

################################################################################
# Ensure configfiles are present
################################################################################

if [ ! -d "$HOME/configfiles" ]
then
    echo "*** Cloning configfiles"
    (cd "$HOME"; git clone git://code.stapelberg.de/configfiles; cd configfiles; ./initialize.sh)
fi

echo "*** done"
