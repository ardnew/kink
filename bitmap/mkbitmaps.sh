#!/bin/bash
#
# Free fonts can be downloaded from https://fonts.google.com.
#
# That Web UI allows you to select any arbitrary typeface and construct your
# own custom collection of fonts, downloadable as a compressed zip archive.
#
# This script can then generate simple status screens for 2/3/4-color e-Ink
# displays containing a given string using each font from a collection.
#
# The following commands will generate "CLEAN"/"DIRTY" status screens like 
# those used in the project "MagTag Dishwasher Status" here:
#
#   https://learn.adafruit.com/magtag-dishwasher-status
#
# Run from the same directory as this script:
#
#  +----------------------------------------------------------------------+
#  | # Extract the font files into an empty directory "ttf".              |
#  | $ unzip -d ttf fonts/fonts.google.com/TrueType.zip                   |
#  |                                                                      |
#  | # Generate bitmaps in new directory "bmp" with opposite fg/bg using  |
#  | # all of the fonts extracted into "ttf" above.                       |
#  | $ ./mkbitmaps.sh -f ttf -o bmp/clean -r CLEAN                        |
#  | $ ./mkbitmaps.sh -f ttf -o bmp/dirty DIRTY                           |
#  +----------------------------------------------------------------------+


# The default parameters below are defined for the 4-level Grayscale ThinkInk 
# display on an Adafruit MagTag.
declare -x                 \
	def_d='4'                \
	def_f='./fonts'          \
	def_i='.*'               \
	def_o='./output'         \
	def_p='24'               \
	def_r='false'            \
	def_s='296x128'          \
	def_t='80'

# The following pallette maps were extracted from the example images here:
#
#   https://learn.adafruit.com/preparing-graphics-for-e-ink-displays/command-line
#
# Using the following command on each image:
#
#   $ convert <IMAGE> -unique-colors -depth 8 txt:

declare -a map_d=(
	# 0 colors
	''
	# 1 colors
	''
	# 2 colors (source: "eink-2color.png")
	'# ImageMagick pixel enumeration: 2,1,255,srgb
0,0: (47,36,41)  #2F2429  srgb(47,36,41)
1,0: (242,244,239)  #F2F4EF  srgb(242,244,239)'
	# 3 colors (source: "eink-3color.png")
	'# ImageMagick pixel enumeration: 3,1,255,srgb
0,0: (47,36,41)  #2F2429  srgb(47,36,41)
1,0: (215,38,39)  #D72627  srgb(215,38,39)
2,0: (242,244,239)  #F2F4EF  srgb(242,244,239)'
	# 4 colors (source: "eink-4gray.png")
	'# ImageMagick pixel enumeration: 4,1,255,srgb
0,0: (47,36,41)  #2F2429  srgb(47,36,41)
1,0: (112,105,107)  #70696B  srgb(112,105,107)
2,0: (177,175,173)  #B1AFAD  srgb(177,175,173)
3,0: (242,244,239)  #F2F4EF  srgb(242,244,239)'
)

usage() {
	cat <<__usage__
Usage:

  ${0##*/} [options] label ...

Arguments:

  label       The literal text to draw on each image

Options:

  -d depth    Color depth (2, 3, or 4) (default "${def_d}")
  -f path     Root directory to search for fonts (default "${def_f}")
  -i pattern  Font inclusion regex pattern (default "${def_i}")
  -o path     Output image root directory (default "${def_o}")
  -p point    Font size of label in points (default "${def_p}")
  -r          Reverse foreground/background (default "${def_r}")
  -s size     Size of each image in pixels (default "${def_s}")
  -t percent  Diffusion percent of dithering (default "${def_t}")

__usage__
}

# Assign $2 to the variable named $1 (or die).
optstr() {
	[[ ${#} -gt 1 ]] ||
		halt "flag requires argument (-${1#opt_})"
	local -n v=${1}
	v=${2}
}

# Append $@ to the array variable named $1 (or die).
optarr() {
	[[ ${#} -gt 1 ]] ||
		halt "flag requires argument (-${1#opt_})"
	local -n v=${1}
	v+=( "${@:2}" )
}

declare -a arg

declare -x       \
	opt_d=${def_d} \
	opt_f=${def_f} \
	opt_i=${def_i} \
	opt_o=${def_o} \
	opt_p=${def_p} \
	opt_r=${def_r} \
	opt_s=${def_s} \
	opt_t=${def_t}

# Poor-man's command-line option parsing
while [[ ${#} -gt 0 ]]; do
	case "${1}" in
		-d) shift; optstr opt_d "${@}" ;;
		-f) shift; optstr opt_f "${@}" ;;
		-i) shift; optstr opt_i "${@}" ;;
		-o) shift; optstr opt_o "${@}" ;;
		-p) shift; optstr opt_p "${@}" ;;
		-r) opt_r="true" ;;
		-s) shift; optstr opt_s "${@}" ;;
		-t) shift; optstr opt_t "${@}" ;;
		-h|--help) usage; exit 0       ;;
		*) arg+=( "${1}" ) ;;              # append arbitrary argument
	esac
	shift
done

[[ ${#arg[@]} -gt 0 ]] || { usage; exit 0; }

declare -x fg=white bg=black
[[ -n ${opt_r} && ${#opt_r} -gt 0 && ! ${opt_r} =~ ^(0|[Ff]) ]] &&
	fg=black bg=white

[[ ${opt_d} =~ ^[234]$ ]] || 
	{ echo "error: invalid color depth: ${opt_d}"; exit 1; }

mkdir -p "${opt_o}" || 
	{ echo "error: cannot create output directory: ${opt_o}"; exit 2; }

while read -re ttf; do

	printf 'Generating %d images with font \"%s\":\n' ${#arg[@]} "${ttf##*/}"

	[[ ${ttf} =~ ${opt_i:-"${def_i}"} ]] || continue

	for a in "${arg[@]}"; do
		fa=$( echo -n "${a}" | sed -E 's/[^a-zA-Z0-9\-_]+/-/g' )
		printf '\t%s -> %s\n' "${a}" "${opt_o}/${fa}.${ttf##*/}.bmp"
		echo "${map_d[${opt_d}]}" | 
			convert \
				-background "${bg}" -fill "${fg}" \
				-font "@${ttf}" \
				-dither FloydSteinberg -define "dither:diffusion-amount=${opt_t}%" \
				-remap txt:- \
				-size "${opt_s}" \
				-gravity "center" \
				"label:${a}" \
				-type truecolor \
				"BMP3:${opt_o}/${fa}.${ttf##*/}.bmp" && 
					 count=$(( count + 1 ))
	done

done < <( find "${opt_f}" -type f -iname '*.ttf' )

