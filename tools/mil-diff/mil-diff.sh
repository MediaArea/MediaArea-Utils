#!/bin/sh

CURRENT_PATH=$(dirname "$0")

MASTER_REPO="https://github.com/MediaArea/MediaInfoLib"
MASTER_BRANCH="master"
NEW_REPO="https://github.com/MediaArea/MediaInfoLib"
NEW_BRANCH="master"

while getopts "a:b:m:r:" option; do
    case "$option" in
        a)
            MASTER_REPO="$OPTARG"
            ;;
        b)
            NEW_BRANCH="$OPTARG"
            ;;
        m)
            MASTER_BRANCH="$OPTARG"
            ;;
        r)
            NEW_REPO="$OPTARG"
            ;;
        \?)
            echo "Usage: -a master_repo -m master_branch -r new_repo -b new_branch" >&2;
            exit 1;
            ;;
    esac
done

#old
if [ ! -d "$CURRENT_PATH/master" ]
then
    git clone --depth 1 "$MASTER_REPO" -b "$MASTER_BRANCH" "$CURRENT_PATH/master"
fi

MASTER_COMPIL_PATH="$CURRENT_PATH/master/Project/GNU/Library/"
cd "$MASTER_COMPIL_PATH"
./autogen.sh
./configure --with-libcurl
make
cd ../../../..

#new
if [ -d "$CURRENT_PATH/new" ]
then
    rm -rf "$CURRENT_PATH/new"
fi

git clone --depth 1 "$NEW_REPO" -b "$NEW_BRANCH" "$CURRENT_PATH/new"

NEW_COMPIL_PATH="$CURRENT_PATH/new/Project/GNU/Library/"
cd "$NEW_COMPIL_PATH"
./autogen.sh
./configure --with-libcurl
make
cd ../../../..


PATH_FILES="$CURRENT_PATH/files"
# clone sample test if needed
if [ ! -d "$PATH_FILES" ]
then
    git clone --depth 1 https://github.com/MediaArea/MediaArea-RegressionTestingFiles "$PATH_FILES"
fi

cd files
git fetch origin
git rebase origin/master
cd ..

# create binary
PKG_CONFIG_PATH_MASTER=`pwd`/master/Project/GNU/Library PKG_CONFIG_PATH_NEW=`pwd`/new/Project/GNU/Library make


# create ouput directory
mkdir -p tmp
mkdir -p error
rm -rf tmp/* error/*


#test files
unset args
while IFS= read -r i; do
    FILE_NAME=$(basename "$i")
    OUTPUT_MASTER_NAME="$CURRENT_PATH/tmp/$FILE_NAME.master.xml"
    `$CURRENT_PATH/create_xml_master "$PATH_FILES/$i" "$OUTPUT_MASTER_NAME"`
    if test $? -ne 0
    then
        echo "Master MediaInfoLib cannot create XML" >&2;
        continue;
    fi

    OUTPUT_NEW_NAME="$CURRENT_PATH/tmp/$FILE_NAME.new.xml"
    `$CURRENT_PATH/create_xml_new "$PATH_FILES/$i" "$OUTPUT_NEW_NAME"`
    if test $? -ne 0
    then
        echo "New MediaInfoLib cannot create XML" >&2;
        continue;
    fi

    DIFF=`diff -u "$OUTPUT_MASTER_NAME" "$OUTPUT_NEW_NAME"`
    if test $? -ne 0
    then
        echo "$PATH_FILES/$i differs" >&2;
        ERROR_DIR="error/$i"
        mkdir -p "$ERROR_DIR"
        echo "$DIFF" > "$ERROR_DIR/$FILE_NAME.diff";
        cp "$OUTPUT_MASTER_NAME" "$ERROR_DIR/."
        cp "$OUTPUT_NEW_NAME" "$ERROR_DIR/."
        continue;
    fi
done < "$PATH_FILES/files.txt"
