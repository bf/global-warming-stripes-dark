#!/bin/bash

# downloads climate change dataset and generates SVG image with dark version of warming stripes

# scale_color_negative="#08306b"
# scale_color_positive="#67000d"

URL="https://www.metoffice.gov.uk/hadobs/hadcrut5/data/HadCRUT.5.0.2.0/analysis/diagnostics/HadCRUT.5.0.2.0.analysis.summary_series.global.annual.csv"

OUTPUT_FILE="warming-stripes.svg"
hsl_hue_negative_temperatures=215
hsl_hue_positive_temperatures=0

# dynamic measurements
temp_min=0
temp_max=0
counter=0

# store all measurements in array
ENTRIES=()

# returns percentage $1 hsl color for a given hue $2
getPercentageHSL() {
	percentage=$(echo "if ($1 > 1) 1 else if ($1 < 0) 0 else $1" | bc)
	hue=$2

	min_saturation=5
	max_saturation=95
	saturation=$(echo "(($percentage) * ($max_saturation-$min_saturation) + $min_saturation) / 100.0" | bc -l)

	min_lightness=5
	max_lightness=30
	lightness=$(echo "((1-$percentage) * ($max_lightness-$min_lightness) + $min_lightness) / 100.0" | bc -l)

	# echo python hsl_to_rgb.py $hue "$saturation" "$lightness" 

	python hls_to_rgb.py $hue $lightness $saturation
	# echo -n "$(python hls_to_rgb.py $hue $lightness $saturation) ; foo: hls($hue, $lightness (min $min_lightness max $max_lightness),  $saturation (min $min_saturation max $max_saturation))"
}

# download dataset and parse
(curl -L "$URL" | tail -n +2 | sed '/^$/d') | (
	while read line; do 
		let counter++;

		year=$(echo $line | cut -d ',' -f 1)
		temp=$(echo $line | cut -d ',' -f 2)
		echo year $year temp $temp

		temp_min=$(echo "if ($temp < $temp_min) $temp else $temp_min" | bc -l)
		temp_max=$(echo "if ($temp > $temp_max) $temp else $temp_max" | bc -l)

		ENTRIES+=($temp)
	done;


	echo "num_entries: $counter"
	echo "temp_min: $temp_min"
	echo "temp_max: $temp_max"

	# define color scale min/max to be equaldistant from zero
	abs_limit=$(echo "if ( -1 * $temp_min > $temp_max ) -1 * $temp_min else $temp_max" | bc)
	# abs_limit="0.75"
	# abs_limit="1"
	echo "abs_limit: $abs_limit"

	width=$(echo "$counter - 1" | bc )
	height=$(printf "%.0f" $(echo "9 / 16.0 * $width" | bc -l))

	TMPFILE="/tmp/convert-hadcrut-to-svg.svg"
	echo "" > $TMPFILE

	# iterate over array
	i=0
	for temp in "${ENTRIES[@]}"
	do 	

		if [[ ${temp:0:1} == "-" ]]; then
			# percentage=$(echo "$temp / (-1 * $abs_limit)" | bc -l)
			percentage=$(echo "$temp / ($temp_min)" | bc -l)
			color=$(getPercentageHSL $percentage $hsl_hue_negative_temperatures)
		else
			# percentage=$(echo "$temp / ($abs_limit)" | bc -l)
			percentage=$(echo "$temp / ($temp_max)" | bc -l)
			color=$(getPercentageHSL $percentage $hsl_hue_positive_temperatures)
		fi

		echo $i $temp $percentage $color

		# echo """
		# 	<line x1='$i' x2='$i' y1='0' y2='$height' style='stroke:$color'>
		# 		<title>$temp</title>
		# 	</line>
		# """ >> $TMPFILE

		let i++;

		# echo "<line x1='$i' x2='$i' y1='0' y2='$height' style='stroke:$color;'/>" >> $TMPFILE
		echo "<rect x='0' y='0' height='$height' width='$i' fill='$color'/>" >> $TMPFILE
	done

	# svg+=("""<?xml version='1.0' encoding='UTF-8'?>
	# <svg xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' width='${width}px' height='${height}px' viewBox='0 0 ${width} ${height}' version='1.1'>
	# <style>line { shape-rendering: crispEdges; stroke-width: 1px; opacity: 50%; }</style>
	# <rect width='100%' height='100%' fill='black' />
	# <g>""")

	echo "<?xml version='1.0' encoding='UTF-8'?><svg width='${width}px' height='${height}px'>" > $OUTPUT_FILE
	# echo "<style>line { shape-rendering: crispEdges; stroke-width: 1px; }</style>" >> $TMPFILE
	# echo "<style>rect { shape-rendering: crispEdges;  }</style>" >> $OUTPUT_FILE

	tac $TMPFILE >> $OUTPUT_FILE
	echo "</svg>" >> $OUTPUT_FILE

	rm $TMPFILE
	# cat $OUTPUT_FILE
)