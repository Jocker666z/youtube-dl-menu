#!/bin/bash
# youtube-dl-menu
#
# Author: Romain Barbarot
# https://github.com/Jocker666z/youtube-dl-menu
#
# licence : GNU GPL-2.0

# Variables Stuff
export PATH=$PATH:/home/$USER/.local/bin
link="$1"
json="/tmp/youtube-dl-menu-$(date +%Y%m%s%N).json"

# Command Stuff
check_bin() {
local yt_dlp_bin_location
local yt_dl_bin_location

yt_dlp_bin_location=$(command -v yt-dlp)
yt_dl_bin_location=$(command -v youtube-dl)

if [[ -n "$yt_dlp_bin_location" ]]; then
	youtube_dl_bin="$yt_dlp_bin_location"
elif [[ -n "$yt_dl_bin_location" ]] && [[ -z "$youtube_dl_bin" ]]; then
	youtube_dl_bin="$yt_dl_bin_location"
else
	echo "Break, youtube-dl or yt-dlp is not installed"
	exit
fi
}

# Tools stuff
calc_size_in_mb() {
local size
local size_in_mb
size="$1"

# If not integer no calculation
if ! [[ "$size" =~ ^[0-9]+$ ]] ; then
	echo "$size"
else
	# MB convert
	size_in_mb=$(bc <<< "scale=1; $size / 1024 / 1024" | sed 's!\.0*$!!')

	# If string start by "." add lead 0
	if [[ "${size_in_mb:0:1}" == "." ]]; then
		echo "0$size_in_mb"
	else
		echo "$size_in_mb"
	fi
fi
}
calc_table_width() {
local string_length
local string_length_calc
string_length=("$@")

for string in "${string_length[@]}"; do

	if [ -z "$string_length_calc" ]; then
		string_length_calc="${#string}"
	fi

	if [[ "$string_length_calc" -lt "${#string}" ]]; then
		string_length_calc="${#string}"
	fi

done

echo "$string_length_calc"
}
domain_detect() {
# https://www.cyberciti.biz/faq/get-extract-domain-name-from-url-in-linux-unix-bash/
domain_link="$link"
 
## Remove protocol part of url  ##
domain_link="${domain_link#http://www.}"
domain_link="${domain_link#http://}"
domain_link="${domain_link#https://www.}"
domain_link="${domain_link#https://}"
domain_link="${domain_link#ftp://}"
domain_link="${domain_link#scp://}"
domain_link="${domain_link#scp://}"
domain_link="${domain_link#sftp://}"
 
## Remove username and/or username:password part of URL  ##
domain_link="${domain_link#*:*@}"
domain_link="${domain_link#*@}"

## Remove rest of urls ##
domain_link="${domain_link%%/*}"
}
playlist_detect() {
playlist=$(echo "$link" | grep "list=")
}

# Json / bash array stuff
extract_info_all() {
youtube-dl --geo-bypass --quiet -j "$link" | jq -r > "$json"
mapfile -t ydl_code < <(jq -r ".formats[].format_id" "$json")
mapfile -t ydl_extension < <(jq -r ".formats[].ext" "$json")
mapfile -t ydl_vcodec < <(jq -r ".formats[].vcodec" "$json" | cut -f1 -d".")
mapfile -t ydl_acodec < <(jq -r ".formats[].acodec" "$json" | cut -f1 -d".")
mapfile -t ydl_kbs < <(jq -r ".formats[].tbr" "$json" | cut -f1 -d".")
mapfile -t ydl_width < <(jq -r ".formats[].width" "$json")
mapfile -t ydl_height < <(jq -r ".formats[].height" "$json")
mapfile -t ydl_size < <(jq -r ".formats[].filesize" "$json")
mapfile -t ydl_fps < <(jq -r ".formats[].fps" "$json")
mapfile -t ydl_notes < <(jq -r ".formats[].format_note" "$json")
rm "$json" &>/dev/null
}
split_audio_video_info() {
for (( i=0; i<=$(( ${#ydl_code[@]} - 1 )); i++ )); do

	# Increment video+audio array
	if [[ "${ydl_vcodec[i]}" != "none" && "${ydl_acodec[i]}" != "none" ]]; then
		video_audio_stream_code+=( "${ydl_code[i]}" ) 
		video_audio_stream_extension+=( "${ydl_extension[i]}" ) 
		video_audio_stream_vcodec+=( "${ydl_vcodec[i]}" ) 
		video_audio_stream_acodec+=( "${ydl_acodec[i]}" ) 
		video_audio_stream_kbs+=( "${ydl_kbs[i]}" ) 
		video_audio_stream_notes+=( "${ydl_notes[i]}" )
		video_audio_stream_size+=( "$(calc_size_in_mb "${ydl_size[i]}")" )
		# If file fps = null -> remove
		if [[ "${ydl_fps[i]}" = "null" ]]; then
			video_audio_stream_image_label="res"
			video_audio_stream_image+=( "${ydl_width[i]}x${ydl_height[i]}" )
		else
			video_audio_stream_image_label="res/fps"
			video_audio_stream_image+=( "${ydl_width[i]}x${ydl_height[i]}/${ydl_fps[i]}" )
		fi
	
	# Increment audio array
	elif [[ "${ydl_vcodec[i]}" = "none" && "${ydl_acodec[i]}" != "none" ]]; then
		audio_stream_code+=( "${ydl_code[i]}" )
		audio_stream_extension+=( "${ydl_extension[i]}" ) 
		audio_stream_codec+=( "${ydl_acodec[i]}" ) 
		audio_stream_kbs+=( "${ydl_kbs[i]}" )
		audio_stream_notes+=( "${ydl_notes[i]}" )
		audio_stream_size+=( "$(calc_size_in_mb "${ydl_size[i]}")" )

	# Increment video array
	elif [[ "${ydl_acodec[i]}" = "none"  && "${ydl_vcodec[i]}" != "none" ]]; then
		video_stream_code+=( "${ydl_code[i]}" ) 
		video_stream_extension+=( "${ydl_extension[i]}" ) 
		video_stream_codec+=( "${ydl_vcodec[i]}" ) 
		video_stream_kbs+=( "${ydl_kbs[i]}" ) 
		video_stream_notes+=( "${ydl_notes[i]}" )
		video_stream_size+=( "$(calc_size_in_mb "${ydl_size[i]}")" )
		# If file fps = null -> remove
		if [[ "${ydl_fps[i]}" = "null" ]]; then
			video_stream_image_label="res"
			video_stream_image+=( "${ydl_width[i]}x${ydl_height[i]}" )
		else
			video_stream_image_label="res/fps"
			video_stream_image+=( "${ydl_width[i]}x${ydl_height[i]}/${ydl_fps[i]}" )
		fi

	fi

done

# add array for index & table separator
for (( i=0; i<=$(( ${#video_audio_stream_code[@]} - 1 )); i++ )); do
	video_audio_stream_menu_code+=( "$i" )
done
for (( i=0; i<=$(( ${#audio_stream_code[@]} - 1 )); i++ )); do
	audio_stream_menu_code+=( "$i" )
done
for (( i=0; i<=$(( ${#video_stream_code[@]} - 1 )); i++ )); do
	video_stream_menu_code+=( "$i" )
done
}

# Print stuff
print_video_audio_list() {
# get larger of column
video_audio_separator_space_string_length=$(( 7 * 2 ))
video_audio_menu_string_length=$(calc_table_width "${video_audio_stream_menu_code[@]}")
video_audio_extension_string_length=$(calc_table_width "${video_audio_stream_extension[@]}")
video_audio_vcodec_string_length=$(calc_table_width "${video_audio_stream_vcodec[@]}")
video_audio_acodec_string_length=$(calc_table_width "${video_audio_stream_acodec[@]}")
video_audio_bitrate_string_length=$(calc_table_width "${video_audio_stream_kbs[@]}")
video_audio_image_string_length=$(calc_table_width "${video_audio_stream_image[@]}")
video_audio_size_string_length=$(calc_table_width "${video_audio_stream_size[@]}")
video_audio_note_string_length=$(calc_table_width "${video_audio_stream_notes[@]}")
video_audio_separator_string_length=$(( video_audio_menu_string_length + video_audio_extension_string_length + video_audio_vcodec_string_length \
							+ video_audio_bitrate_string_length + video_audio_size_string_length + video_audio_image_string_length \
							+ video_audio_note_string_length + video_audio_separator_space_string_length + video_audio_acodec_string_length))

# Table
printf '%*s' "$video_audio_separator_string_length" | tr ' ' "-"; echo
paste <(printf "%-${video_audio_menu_string_length}.${video_audio_menu_string_length}s\n" "") \
	<(printf "%-${video_audio_extension_string_length}.${video_audio_extension_string_length}s\n" "ext") \
	<(printf "%-${video_audio_vcodec_string_length}.${video_audio_vcodec_string_length}s\n" "vfmt") \
	<(printf "%-${video_audio_acodec_string_length}.${video_audio_acodec_string_length}s\n" "afmt") \
	<(printf "%-${video_audio_bitrate_string_length}.${video_audio_bitrate_string_length}s\n" "kbs") \
	<(printf "%-${video_audio_image_string_length}.${video_audio_image_string_length}s\n" "$video_audio_stream_image_label") \
	<(printf "%-${video_audio_size_string_length}.${video_audio_size_string_length}s\n" "mb") \
	<(printf "%-${video_audio_note_string_length}.${video_audio_note_string_length}s\n" "note") | column -s $'\t' -t
printf '%*s' "$video_audio_separator_string_length" | tr ' ' "-"; echo
paste <(printf "%-${video_audio_menu_string_length}.${video_audio_menu_string_length}s\n" "${video_audio_stream_menu_code[@]}") \
	<(printf "%-${video_audio_extension_string_length}.${video_audio_extension_string_length}s\n" "${video_audio_stream_extension[@]}") \
	<(printf "%-${video_audio_vcodec_string_length}.${video_audio_vcodec_string_length}s\n" "${video_audio_stream_vcodec[@]}") \
	<(printf "%-${video_audio_acodec_string_length}.${video_audio_acodec_string_length}s\n" "${video_audio_stream_acodec[@]}") \
	<(printf "%-${video_audio_bitrate_string_length}.${video_audio_bitrate_string_length}s\n" "${video_audio_stream_kbs[@]}") \
	<(printf "%-${video_audio_image_string_length}.${video_audio_image_string_length}s\n" "${video_audio_stream_image[@]}") \
	<(printf "%-${video_audio_size_string_length}.${video_audio_size_string_length}s\n" "${video_audio_stream_size[@]}") \
	<(printf "%-${video_audio_note_string_length}.${video_audio_note_string_length}s\n" "${video_audio_stream_notes[@]}") | column -s $'\t' -t 2>/dev/null
printf '%*s' "$video_audio_separator_string_length" | tr ' ' "-"; echo
}
print_audio_list() {
# get larger of column
audio_separator_space_string_length=$(( 5 * 2 ))
audio_menu_string_length=$(calc_table_width "${audio_stream_menu_code[@]}")
audio_extension_string_length=$(calc_table_width "${audio_stream_extension[@]}")
audio_codec_string_length=$(calc_table_width "${audio_stream_codec[@]}")
audio_bitrate_string_length=$(calc_table_width "${audio_stream_kbs[@]}")
audio_size_string_length=$(calc_table_width "${audio_stream_size[@]}")
audio_note_string_length=$(calc_table_width "${audio_stream_notes[@]}")
audio_separator_string_length=$(( audio_menu_string_length + audio_extension_string_length + audio_codec_string_length \
							+ audio_bitrate_string_length + audio_size_string_length + audio_separator_space_string_length\
							+ audio_note_string_length ))

# Table
printf '%*s' "$audio_separator_string_length" | tr ' ' "-"; echo
paste <(printf "%-${audio_menu_string_length}.${audio_menu_string_length}s\n" "") \
	<(printf "%-${audio_extension_string_length}.${audio_extension_string_length}s\n" "ext") \
	<(printf "%-${audio_codec_string_length}.${audio_codec_string_length}s\n" "fmt") \
	<(printf "%-${audio_bitrate_string_length}.${audio_bitrate_string_length}s\n" "kbs") \
	<(printf "%-${audio_size_string_length}.${audio_size_string_length}s\n" "mb") \
	<(printf "%-${audio_note_string_length}.${audio_note_string_length}s\n" "note") | column -s $'\t' -t
printf '%*s' "$audio_separator_string_length" | tr ' ' "-"; echo
paste <(printf "%-${audio_menu_string_length}.${audio_menu_string_length}s\n" "${audio_stream_menu_code[@]}") \
	<(printf "%-${audio_extension_string_length}.${audio_extension_string_length}s\n" "${audio_stream_extension[@]}") \
	<(printf "%-${audio_codec_string_length}.${audio_codec_string_length}s\n" "${audio_stream_codec[@]}") \
	<(printf "%-${audio_bitrate_string_length}.${audio_bitrate_string_length}s\n" "${audio_stream_kbs[@]}") \
	<(printf "%-${audio_size_string_length}.${audio_size_string_length}s\n" "${audio_stream_size[@]}") \
	<(printf "%-${audio_note_string_length}.${audio_note_string_length}s\n" "${audio_stream_notes[@]}") | column -s $'\t' -t 2>/dev/null
printf '%*s' "$audio_separator_string_length" | tr ' ' "-"; echo
}
print_video_list() {
# get larger of column
video_separator_space_string_length=$(( 6 * 2 ))
video_menu_string_length=$(calc_table_width "${video_stream_menu_code[@]}")
video_extension_string_length=$(calc_table_width "${video_stream_extension[@]}")
video_codec_string_length=$(calc_table_width "${video_stream_codec[@]}")
video_bitrate_string_length=$(calc_table_width "${video_stream_kbs[@]}")
video_size_string_length=$(calc_table_width "${video_stream_size[@]}")
video_image_string_length=$(calc_table_width "${video_stream_image[@]}")
video_note_string_length=$(calc_table_width "${video_stream_notes[@]}")
video_separator_string_length=$(( video_menu_string_length + video_extension_string_length + video_codec_string_length \
							+ video_bitrate_string_length + video_size_string_length + video_separator_space_string_length \
							+ video_image_string_length + video_note_string_length))

# Table
printf '%*s' "$video_separator_string_length" | tr ' ' "-"; echo
paste <(printf "%-${video_menu_string_length}.${video_menu_string_length}s\n" "") \
	<(printf "%-${video_extension_string_length}.${video_extension_string_length}s\n" "ext") \
	<(printf "%-${video_codec_string_length}.${video_codec_string_length}s\n" "fmt") \
	<(printf "%-${video_bitrate_string_length}.${video_bitrate_string_length}s\n" "kbs") \
	<(printf "%-${video_image_string_length}.${video_image_string_length}s\n" "$video_stream_image_label") \
	<(printf "%-${video_size_string_length}.${video_size_string_length}s\n" "mb") \
	<(printf "%-${video_note_string_length}.${video_note_string_length}s\n" "note") | column -s $'\t' -t
printf '%*s' "$video_separator_string_length" | tr ' ' "-"; echo
paste <(printf "%-${video_menu_string_length}.${video_menu_string_length}s\n" "${video_stream_menu_code[@]}") \
	<(printf "%-${video_extension_string_length}.${video_extension_string_length}s\n" "${video_stream_extension[@]}") \
	<(printf "%-${video_codec_string_length}.${video_codec_string_length}s\n" "${video_stream_codec[@]}") \
	<(printf "%-${video_bitrate_string_length}.${video_bitrate_string_length}s\n" "${video_stream_kbs[@]}") \
	<(printf "%-${video_image_string_length}.${video_image_string_length}s\n" "${video_stream_image[@]}") \
	<(printf "%-${video_size_string_length}.${video_size_string_length}s\n" "${video_stream_size[@]}") \
	<(printf "%-${video_note_string_length}.${video_note_string_length}s\n" "${video_stream_notes[@]}") | column -s $'\t' -t 2>/dev/null
printf '%*s' "$video_separator_string_length" | tr ' ' "-"; echo
}

# Question stuff
print_audio_question() {
read -e -r -p "Select the preferred audio stream: " select_audio_stream_menu_code

# Populate variable with selected stream
audio_stream="${audio_stream_code[$select_audio_stream_menu_code]}"
}
print_video_question() {
read -e -r -p "Select the preferred video stream: " select_video_stream_menu_code

# Populate variable with selected stream
video_stream="${video_stream_code[$select_video_stream_menu_code]}"
}
print_video_audio_question() {
read -e -r -p "Select the preferred quality: " select_video_audio_stream_menu_code

# Populate variable with selected stream
video_audio_stream="${video_audio_stream_code[$select_video_audio_stream_menu_code]}"
}

if [ "$#" -lt "1" ]; then
	echo "Without url it doesn't work"
	exit

elif [ "$#" -ge "2" ]; then
	echo "One url at a time"
	exit

else

	if [[ "$link" == "http"* ]]; then

		check_bin
		playlist_detect

		if [ -z "$playlist" ]; then

			# Get domain
			domain_detect
			# Get infos
			extract_info_all
			split_audio_video_info

			# Youtube
			if [[ "${domain_link}" = "youtube.com" ]]; then
				print_video_list
				print_video_question
				print_audio_list
				print_audio_question
				"$youtube_dl_bin" --geo-bypass --no-warnings -f "$video_stream"+"$audio_stream" "$link"

			# Other
			else
				print_video_audio_list
				print_video_audio_question
				"$youtube_dl_bin" --geo-bypass --no-warnings -f "$video_audio_stream" "$link"

			fi

		else
			echo "Playlist not supported"
			exit
		fi

	else
		echo "$link is not an url"
		exit
	fi

fi
