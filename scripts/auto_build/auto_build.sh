#!/bin/sh
# --
# OTOBO is a web-based ticketing system for service organisations.
# --
# Copyright (C) 2001-2020 OTRS AG, https://otrs.com/
# Copyright (C) 2019-2022 Rother OSS GmbH, https://otobo.de/
# --
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later version.
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.
# --

# auto_build.sh - build automatically OTOBO tar, rpm and src-rpm

echo "auto_build.sh - build OTOBO release files"
echo "Copyright (C) 2019-2021 Rother OSS GmbH, https://otobo.de/";

PATH_TO_CVS_SRC=$1
PRODUCT=OTOBO
VERSION=$2
RELEASE=$3
ARCHIVE_DIR="otobo-$VERSION"
PACKAGE=otobo
PACKAGE_BUILD_DIR="/tmp/$PACKAGE-build"
PACKAGE_DEST_DIR="/tmp/$PACKAGE-packages"
PACKAGE_TMP_SPEC="/tmp/$PACKAGE.spec"
RPM_BUILD="rpmbuild"
#RPM_BUILD="rpm"


if ! test $PATH_TO_CVS_SRC || ! test $VERSION || ! test $RELEASE; then
    # --
    # build src needed
    # --
    echo ""
    echo "Usage: auto_build.sh <PATH_TO_CVS_SRC> <VERSION> <BUILD>"
    echo ""
    echo "  Try: auto_build.sh /home/ernie/src/otobo 10.1.0.beta1 01"
    echo ""
    exit 1;
else
    # --
    # check dir
    # --
    if ! test -e $PATH_TO_CVS_SRC/RELEASE; then
        echo "Error: $PATH_TO_CVS_SRC is not OTOBO CVS directory!"
        exit 1;
    fi
fi

# --
# get system info
# --
if test -d /usr/src/redhat/RPMS/; then
    SYSTEM_RPM_DIR=/usr/src/redhat/RPMS/
else
    SYSTEM_RPM_DIR=/usr/src/packages/RPMS/
fi

if test -d /usr/src/redhat/SRPMS/; then
    SYSTEM_SRPM_DIR=/usr/src/redhat/SRPMS/
else
    SYSTEM_SRPM_DIR=/usr/src/packages/SRPMS/
fi

if test -d /usr/src/redhat/SOURCES/; then
    SYSTEM_SOURCE_DIR=/usr/src/redhat/SOURCES/
else
    SYSTEM_SOURCE_DIR=/usr/src/packages/SOURCES/
fi

# --
# cleanup system dirs
# --
rm -rf $SYSTEM_RPM_DIR/*/$PACKAGE*$VERSION*$RELEASE*.rpm
rm -rf $SYSTEM_SRPM_DIR/$PACKAGE*$VERSION*$RELEASE*.src.rpm

# --
# RPM and SRPM dir
# --
rm -rf $PACKAGE_DEST_DIR
mkdir $PACKAGE_DEST_DIR

# --
# build
# --
rm -rf $PACKAGE_BUILD_DIR || exit 1;
mkdir -p $PACKAGE_BUILD_DIR/$ARCHIVE_DIR/ || exit 1;

cp -a $PATH_TO_CVS_SRC/.*rc.dist $PACKAGE_BUILD_DIR/$ARCHIVE_DIR/ || exit 1;
cp -a $PATH_TO_CVS_SRC/.mailfilter.dist $PACKAGE_BUILD_DIR/$ARCHIVE_DIR/ || exit 1;
cp -a $PATH_TO_CVS_SRC/.bash_completion $PACKAGE_BUILD_DIR/$ARCHIVE_DIR/ || exit 1;
cp -a $PATH_TO_CVS_SRC/* $PACKAGE_BUILD_DIR/$ARCHIVE_DIR/ || exit 1;

# --
# update RELEASE
# --
COMMIT_ID=$( cd $(dirname "$0")/../..; git rev-parse HEAD)
if ! test $COMMIT_ID
then
    echo "Error: could not determine git commit id."
    exit 1
fi

RELEASEFILE=$PACKAGE_BUILD_DIR/$ARCHIVE_DIR/RELEASE
echo "PRODUCT = $PRODUCT" > $RELEASEFILE
echo "VERSION = $VERSION" >> $RELEASEFILE
echo "BUILDDATE = `date`" >> $RELEASEFILE
echo "BUILDHOST = `hostname -f`" >> $RELEASEFILE
echo "COMMIT_ID = $COMMIT_ID" >> $RELEASEFILE

# --
# cleanup
# --
cd $PACKAGE_BUILD_DIR/$ARCHIVE_DIR/ || exit 1;

# remove old sessions, articles and spool and other stuff
# (remainders of a running system, should not really happen)
rm -rf .gitignore var/sessions/* var/article/* var/spool/* Kernel/Config.pm
# remove development content
rm -rf development
# remove swap/temp stuff
find -name ".#*" | xargs rm -rf
find -name ".keep" | xargs rm -f

# mk ARCHIVE
bin/otobo.CheckSum.pl -a create
# Create needed directories
mkdir -p var/tmp var/article var/log

function CreateArchive() {
    SUFFIX=$1
    COMMANDLINE=$2

    cd $PACKAGE_BUILD_DIR/ || exit 1;
    SOURCE_LOCATION=$SYSTEM_SOURCE_DIR/$PACKAGE-$VERSION.$SUFFIX
    rm $SOURCE_LOCATION
    echo "Building $SOURCE_LOCATION..."
    $COMMANDLINE $SOURCE_LOCATION $ARCHIVE_DIR/ > /dev/null || exit 1;
    cp $SOURCE_LOCATION $PACKAGE_DEST_DIR/
}

CreateArchive "tar.gz"  "tar -czf"
CreateArchive "tar.bz2" "tar -cjf"
CreateArchive "zip"     "zip -r"

# --
# create rpm spec files
# --
DESCRIPTION=$PATH_TO_CVS_SRC/scripts/auto_build/description.txt
FILES=$PATH_TO_CVS_SRC/scripts/auto_build/files.txt

function CreateRPM() {
    DistroName=$1
    SpecfileName=$2
    TargetPath=$3

    echo "Building $DistroName rpm..."

    specfile=$PACKAGE_TMP_SPEC
    # replace version and release
    cat $ARCHIVE_DIR/scripts/auto_build/spec/$SpecfileName | sed "s/^Version:.*/Version:      $VERSION/" | sed "s/^Release:.*/Release:      $RELEASE/" > $specfile
    $RPM_BUILD -ba --clean $specfile || exit 1;
    rm $specfile || exit 1;

    mkdir -p $PACKAGE_DEST_DIR/RPMS/$TargetPath
    mv $SYSTEM_RPM_DIR/*/$PACKAGE*$VERSION*$RELEASE*.rpm $PACKAGE_DEST_DIR/RPMS/$TargetPath
    mkdir -p $PACKAGE_DEST_DIR/SRPMS/$TargetPath
    mv $SYSTEM_SRPM_DIR/$PACKAGE*$VERSION*$RELEASE*.src.rpm $PACKAGE_DEST_DIR/SRPMS/$TargetPath
}

CreateRPM "SuSE 12"   "suse12-otobo.spec"   "suse/12/"
CreateRPM "SuSE 13"   "suse13-otobo.spec"   "suse/13/"
CreateRPM "Fedora 25" "fedora25-otobo.spec" "fedora/25/"
CreateRPM "Fedora 26" "fedora26-otobo.spec" "fedora/26/"
CreateRPM "RHEL 7"    "rhel7-otobo.spec"    "rhel/7"

echo "-----------------------------------------------------------------";
echo "You will find your tar.gz, RPMs and SRPMs in $PACKAGE_DEST_DIR";
cd $PACKAGE_DEST_DIR
find . -name "*$PACKAGE*" | xargs ls -lo
echo "-----------------------------------------------------------------";
if which md5sum >> /dev/null; then
    echo "MD5 message digest (128-bit) checksums in wiki table format";
    find . -name "*$PACKAGE*" | xargs md5sum | sed -e "s/^/| /" -e "s/\.\//| http:\/\/ftp.otobo.ch\/pub\/otobo\//" -e "s/$/ |/"
else
    echo "No md5sum found in \$PATH!"
fi
echo "--------------------------------------------------------------------------";
echo "Note: You may have to tag your git tree: git tag rel-6_x_x -a -m \"6.x.x\"";
echo "--------------------------------------------------------------------------";

# --
# cleanup
# --
rm -rf $PACKAGE_BUILD_DIR
rm -rf $PACKAGE_TMP_SPEC
