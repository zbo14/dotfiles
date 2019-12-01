#!/bin/bash -e

function decrypt() {
  if [[ -z "$1" ]]; then
    echo "Usage: decrypt /path/to/thing"
    return 1
  fi

  base="$(basename "$(basename "$1" .gpg)" .zip)"
  dir="$(dirname "$1")"
  cd "$dir"

  if [[ -f "$base.gpg" ]]; then
    echo "Decrypting $base.gpg"
    gpg --output "$base" --decrypt "$base.gpg"
    rm "$base.gpg"
  elif [[ -f "$base.zip.gpg" ]]; then
    echo "Decrypting $base.zip.gpg"
    gpg --output "$base.zip" --decrypt "$base.zip.gpg"
    rm "$base.zip.gpg"

    echo "Unzipping $base.zip"
    unzip "$base.zip"
    rm "$base.zip"
  else
    echo "No $base.gpg or $base.zip.gpg file!"
    return 1
  fi
}

function encrypt() {
  if [[ -z "$1" ]]; then
    echo "Usage: encrypt /path/to/thing"
    return 1
  fi

  base="$(basename "$1")"
  dir="$(dirname "$1")"
  cd "$dir"

  if [[ -d "$base" ]]; then
    echo "Zipping $base directory"
    zip -r "$base.zip" "$base"
    rm -r "$base"
    base="$base.zip"
  fi

  if [[ -f "$base" ]]; then
    echo "Encrypting $base"
    gpg --symmetric "$base"
    gpgconf --reload gpg-agent
    rm "$base"
  else
    echo "No file or directory $base!"
    return 1
  fi
}

function recrypt() {
  if [[ -z "$1" ]]; then
    echo "Usage: recrypt /path/to/thing"
    return 1
  fi

  decrypt "$1"

  [[ "$?" == 0 ]] || return "$?"

  read -p "Press enter to re-encrypt..."

  dir="$(dirname "$1")"
  base="$(basename "$(basename "$1" .gpg)" .zip)"

  encrypt "$dir/$base"

  return "$?"
}

function shut() {
  kill -9 "$(lsof -ti :"$1")"
}