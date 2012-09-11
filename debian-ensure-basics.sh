#!/bin/bash
# vim:ts=4:sw=4:expandtab
# © 2012 Michael Stapelberg
#
# wget -O- d.zekjur.net | bash -s

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
    echo "$CURRENT_LOCALES" | grep -q "^$locale.UTF-8 UTF-8$"
    if [ $? -ne 0 ]
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
################################################################################

# Ensure this directory exists, we might need to use it.
mkdir -p /etc/apt/apt.conf.d
MATCHING_LINES=$(apt-config dump | grep '^APT::Install-\(Recommends\|Suggests\) "false";$' | wc -l)
if [ "$MATCHING_LINES" -ne 2 ]
then
    echo "*** Setting APT::Install-Recommends and APT::Install-Suggests to false..."
    echo 'APT::Install-Recommends "false";' > /etc/apt/apt.conf.d/05disable-recommends
    echo 'APT::Install-Suggests "false";' > /etc/apt/apt.conf.d/05disable-suggests
fi

apt-config dump | grep -q '^Acquire::Pdiffs "no";$'
if [ $? -ne 0 ]
then
    echo "*** Disabling APT Pdiffs..."
    echo 'Acquire::Pdiffs "no";' > /etc/apt/apt.conf.d/06disable-pdiffs
fi

################################################################################
# Ensure the following packages are installed:
# zsh, vim, sudo, less, git
################################################################################
for package in zsh vim sudo less git
do
    dpkg -l "$package" >/dev/null
    if [ $? -ne 0 ]
    then
        echo "*** Installing $package..."
        DEBIAN_FRONTEND=noninteractive \
        DEBCONF_NONINTERACTIVE_SEEN=true \
        LC_ALL=C \
        LANGUAGE=C \
        LANG=C \
            apt-get install --force-yes -y install "$package"
    fi
done

################################################################################
# Ensure zsh is the login shell (if it could be installed).
################################################################################

# TODO

################################################################################
# Ensure configfiles are present
################################################################################

# TODO

echo "*** done"