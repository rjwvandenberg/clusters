#!/bin/bash

USAGE=$'USAGE: download-box.sh <org> <box>\n

The script downloads the latest virtualbox <org>/<box> image from vagrant cloud and extracts the files.'
DOWNLOAD=false

if [ $# -ne 2 ]; then
  echo "$USAGE"
  exit
fi

# test prerequisites
if ! command -v jq > /dev/null ; then
  echo "Error: Requires jq to process json."
  exit
fi

if ! command -v curl > /dev/null ; then
  echo "Error: Requires curl to download files."
  exit
fi

if ! command -v tar > /dev/null ; then
  echo "Error: Requires tar for unpacking files."
  exit
fi


# prepare variables
org=$1
box=$2
cwd=$(dirname $0)
url="https://vagrantcloud.com/api/v2/vagrant/$org/$box"

if [ -z $org ]; then
  echo "Error: <org> is empty"
  echo "$USAGE"
  exit
fi

if [ -z $box ]; then
  echo "Error: <box> is empty"
  echo "$USAGE"
  exit
fi

echo "Retrieving $url"
boxurls=$(curl "$url")
version=$(echo $boxurls | jq -r '.versions[0].version | select(type=="string")')

if [ -z $version ]; then
  echo "Error: could not find version string in $url"
  exit
else 
  echo "Version $version"
fi

#hyperv=$(echo $boxurls | jq '.versions[0].providers[].name | select(.=="hyperv") | select(type=="string")')
#if ! [ -z $hyperv ]; then
#  echo "Vagrant has a hyperv provider available, stopping conversion."
#  exit
#fi

boxurl=$(echo $boxurls | jq -r '.versions[0].providers[] | select(.name=="virtualbox") | .url | select(type=="string")')
if [ -z $boxurl ]; then
  echo "Error: no url found"
  exit
fi
echo "url: $boxurl"

boxname=$(basename "$boxurl")
outputpath="$cwd/$boxname"
echo "Downloading $boxname to $outputpath"

# dont't download if DOWNLOAD IS false
# follow redirect -L
$DOWNLOAD && curl -L $boxurl -o $outputpath
if $DOWNLOAD && [ $? -ne 0 ]; then
  echo "Error: encountered non zero exitcode($?) in curl"
  exit
fi
echo "Done downloading"
echo "$outputpath is a $(file $outputpath)"

boxfilespath="$cwd/boxfiles"
# unpack and edit the files
echo "unpacking to $boxfilespath"
mkdir $cwd/boxfiles
tar -xvf $outputpath -C $boxfilespath

# https://developer.hashicorp.com/vagrant/docs/boxes/format
# requires 
# - vm artifact in format that hyperv accepts
# - metadata.json 
# - Vagrantfile

# ubuntu noble 24.04 apt currently broken repos due to xz cve.
# no point in repackaging, lets use default 22.04 and create our own.