#!/usr/bin/env Rscript
#
# Regenerates img/og-card.png, the 1200x630 share image that Open Graph and
# Twitter Card consumers (Bluesky, LinkedIn, Slack, Mastodon) fetch.
#
# NOT part of `make`. The card only changes when the name, title, or portrait
# changes, so it is committed as a binary and rebuilt by hand:
#
#     Rscript R/build_og_card.R
#
# Needs macOS `sips` to decode the JPEG portrait -- the small `png` package is
# the only image reader available here, and it cannot read JPEG.

out_file <- "img/og-card.png"
portrait <- "img/george-g-vega-yon-university-of-utah.jpg"

W <- 1200L
H <- 630L

orange <- "#ff8000"
ink <- "#1c1917"
muted <- "#57534e"
paper <- "#ffffff"

font <- "Helvetica Neue"

# --- portrait: decode, crop to the face, mask to a circle -------------------

# sips only converts and scales -- it crops around the centre, and the subject
# stands at the left edge of this frame -- so the crop box is applied here, in
# source pixels of the 900x1200 downscale.
tmp_png <- tempfile(fileext = ".png")
system2("sips", c(
  "-s", "format", "png", "-Z", "1200",
  shQuote(portrait), "--out", shQuote(tmp_png)
), stdout = FALSE, stderr = FALSE)

crop_rows <- 300:779
crop_cols <- 1:480

full <- png::readPNG(tmp_png)
# Fail loudly rather than mis-crop if the portrait is ever swapped out.
stopifnot(dim(full)[1] == 1200L, dim(full)[2] == 900L)

img <- full[crop_rows, crop_cols, 1:3, drop = FALSE]

n <- dim(img)[1]
# Antialiased circular alpha: 1 inside, feathered over the outermost 1.5px.
cc <- (n + 1) / 2
d <- sqrt(outer((seq_len(n) - cc)^2, (seq_len(n) - cc)^2, "+"))
alpha <- pmin(1, pmax(0, (n / 2 - d) / 1.5))
img <- array(c(img, alpha), dim = c(n, n, 4L))

# --- canvas -----------------------------------------------------------------

ragg::agg_png(out_file, width = W, height = H, units = "px", res = 72,
              background = paper)

par(mar = rep(0, 4), xaxs = "i", yaxs = "i")
plot.new()
plot.window(xlim = c(0, W), ylim = c(0, H))

# Brand bar along the top, mirroring the navbar.
rect(0, H - 14, W, H, col = orange, border = NA)

# A wash of orange behind the portrait so the circle sits on something.
rect(W - 470, 0, W, H - 14, col = "#fff7ed", border = NA)

# --- portrait ---------------------------------------------------------------

cx <- W - 235
cy <- H / 2 - 7
r <- 190

# White ring, drawn as a filled circle one stroke wider than the photo.
theta <- seq(0, 2 * pi, length.out = 256)
polygon(cx + (r + 9) * cos(theta), cy + (r + 9) * sin(theta),
        col = paper, border = NA)
rasterImage(img, cx - r, cy - r, cx + r, cy + r, interpolate = TRUE)

# --- text -------------------------------------------------------------------

x0 <- 78

text(x0, 470, "George G.", adj = c(0, 0), family = font, font = 2,
     cex = 64 / 12, col = ink)
text(x0, 386, "Vega Yon, Ph.D.", adj = c(0, 0), family = font, font = 2,
     cex = 64 / 12, col = ink)

rect(x0, 344, x0 + 96, 350, col = orange, border = NA)

text(x0, 286, "Associate Professor of Research", adj = c(0, 0), family = font,
     cex = 30 / 12, col = ink)
text(x0, 246, "University of Utah", adj = c(0, 0), family = font,
     cex = 30 / 12, col = muted)

text(x0, 176, "Statistical computing · Network science", adj = c(0, 0),
     family = font, cex = 26 / 12, col = muted)
text(x0, 140, "Scientific software development", adj = c(0, 0),
     family = font, cex = 26 / 12, col = muted)

text(x0, 62, "ggvy.cl", adj = c(0, 0), family = font, font = 2,
     cex = 28 / 12, col = orange)

dev.off()
