#!/bin/sh

if [ -d $SRCROOT/.git ]
then
  STATUS_REGEX="([U \+-])[0-9a-f]{40} ([^ ]+)( \(.+\))?"
  STATUS=`git submodule status`
  (IFS="
"
  for LINE in $STATUS; do
    if [[ $LINE =~ $STATUS_REGEX ]]
    then
      if [ ${BASH_REMATCH[1]} == "-" ]
      then
        echo "warning: Submodule ${BASH_REMATCH[2]} is not initialized"
      fi
    else
      echo "warning: Can't parse git submodule status: $LINE"
    fi
  done
  )
else
  echo "warning: Git repository not found. Submodules may be missing."
fi

which -s brew
if [ $? -ne 0 && ! -e /usr/local/bin/brew ]
then
  echo "warning: Brew not found. See http://brew.sh/"
fi

which -s cmake
if [ $? -ne 0 ]
then
  echo "warning: CMake not found. See http://cmake.org/"
fi
