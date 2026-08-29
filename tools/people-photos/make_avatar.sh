#!/bin/sh
# Crop and resize one candidate photo to the site's avatar format: a square
# JPEG, 240px per side (2x the ~24px card display size, comfortably covers
# the largest use -- the ~56px People-page avatar -- at retina density too).
#
# Usage: make_avatar.sh in.jpg out.jpg [side]
#
# sips (macOS only, no extra dependency) can center-crop but cannot target an
# off-center region. That is fine for a proper headshot where the face is
# already centered -- most institutional directory photos are -- but it WILL
# behead a tall portrait or crop out the subject of a candid/selfie shot
# where the face sits off to one side. review.R shows the cropped preview
# next to the original specifically so a human catches that before approval;
# fix a bad crop by hand in Preview.app (or re-run with a manually pre-cropped
# `in.jpg`) rather than trusting this script blindly for anything but a
# centered headshot.
set -eu

in=$1
out=$2
side=${3:-240}

w=$(sips -g pixelWidth  "$in" | awk '/pixelWidth/{print $2}')
h=$(sips -g pixelHeight "$in" | awk '/pixelHeight/{print $2}')

cp "$in" "$out"

# Resample the shorter side up/down to `side` first, so the subsequent
# center crop has a full `side`x`side` square to take from.
if [ "$w" -lt "$h" ]; then
  sips --resampleWidth "$side" "$out" >/dev/null
else
  sips --resampleHeight "$side" "$out" >/dev/null
fi

sips -c "$side" "$side" -s format jpeg -s formatOptions 80 "$out" >/dev/null

echo "wrote $out (${side}x${side})"
