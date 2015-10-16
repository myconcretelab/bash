#!/bin/bash

cd /Applications/MAMP/htdocs/_packages5.7

if [ "$1" == "" ]
  then
  echo "ERROR : Nothing to zip"
  exit
fi

## On supprime le zip si il existe
if [ -a "$1.zip" ]; then
  read -p " - We will delete "$1.zip", Are you sure ? y/n " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -f "$1.zip"
  fi
fi

find $1 -path '*/.*' -prune -o -type f -print | zip $1.zip -@
