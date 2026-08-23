#!/usr/bin/env bash
set -u
set -o pipefail

SOURCE_ROOT="${SOURCE_ROOT:-$HOME/storage/shared/Music/FLAC}"
DEST_ROOT="${DEST_ROOT:-$HOME/storage/shared/Music/MP3}"
LAST_ERROR_LOG=""
for cmd in ffmpeg ffprobe find sort awk mktemp stat date tput; do command -v "$cmd" >/dev/null 2>&1 || { printf 'Missing dependency: %s\n' "$cmd" >&2; exit 1; }; done

terminal_width(){ local w; w="$(tput cols 2>/dev/null || echo 80)"; [[ "$w" =~ ^[0-9]+$ ]] || w=80; ((w<20))&&w=20; printf '%s' "$w"; }
WIDTH="$(terminal_width)"
clear_screen(){ printf '\033[2J\033[H'; }
hide_cursor(){ printf '\033[?25l'; }
show_cursor(){ printf '\033[?25h'; }
trap 'show_cursor; printf "\n"' EXIT INT TERM
hsize(){ awk -v b="${1:-0}" 'BEGIN{split("B KiB MiB GiB TiB",u);i=1;while(b>=1024&&i<5){b/=1024;i++};if(i==1)printf "%.0f %s",b,u[i];else printf "%.1f %s",b,u[i]}' ; }
hdur(){ awk -v s="${1:-0}" 'BEGIN{s+=0;h=int(s/3600);m=int((s%3600)/60);x=int(s%60);if(h)printf "%02dh%02dm%02ds",h,m,x;else printf "%02dm%02ds",m,x}' ; }
size_of(){ stat -c '%s' "$1" 2>/dev/null || stat -f '%z' "$1" 2>/dev/null || echo 0; }
duration(){ ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "$1" 2>/dev/null; }
duration_us(){ awk -v s="$(duration "$1")" 'BEGIN{printf "%.0f",(s+0)*1000000}'; }
cover(){ [[ "$(ffprobe -v error -select_streams v -show_entries stream=disposition.attached_pic -of default=nw=1:nk=1 "$1" 2>/dev/null)" == 1 ]]; }

# Simple ASCII bar. Its full rendered width is exactly the terminal width.
readable_bar(){
 local pct=$1 width=$2 inner filled empty
 ((pct<0))&&pct=0; ((pct>100))&&pct=100
 inner=$((width-9)); ((inner<3))&&inner=3
 filled=$((inner*pct/100)); empty=$((inner-filled))
 printf '['
 printf '%*s' "$filled" '' | tr ' ' '#'
 printf '%*s' "$empty" '' | tr ' ' '-'
 printf '] %3d%%' "$pct"
}
summary_bar(){ local pct=$1 width=$2 filled empty; ((pct<0))&&pct=0; ((pct>100))&&pct=100; filled=$((width*pct/100)); empty=$((width-filled)); printf '%*s' "$filled" ''|tr ' ' '#'; printf '%*s' "$empty" ''|tr ' ' '.'; }
fit(){ local s=$1 w=${2:-$WIDTH}; if ((${#s}>w)); then printf '%s...' "${s:0:w-3}"; else printf '%s' "$s"; fi; }

# The frozen greeting has Artist: on line 6. The live screens use exactly the
# same line as their anchor. We never clear/repaint the whole conversion frame.
ARTIST_ROW=6
CONVERSION_BAR_ROW=8
BITRATE_ROW=10
SIZE_ROW=11
ELAPSED_ROW=13
ETA_ROW=14
OVERALL_BAR_ROW=16
OVERALL_TEXT_ROW=17

move_to(){ printf '\033[%d;%dH' "$1" "$2"; }
clear_row(){ move_to "$1" 1; printf '\033[2K'; }
write_at(){ local row=$1 text=$2; clear_row "$row"; move_to "$row" 1; printf '%s' "$text"; }
write_bar(){ local row=$1 pct=$2; clear_row "$row"; move_to "$row" 1; readable_bar "$pct" "$WIDTH"; }

find_artist(){ local wanted=$1 d base; [[ -d "$SOURCE_ROOT/$wanted" ]]&&{ printf '%s\n' "$SOURCE_ROOT/$wanted";return; }; while IFS= read -r -d '' d; do base=${d##*/}; [[ "${base,,}" == "${wanted,,}" ]]&&{ printf '%s\n' "$d";return;}; done < <(find "$SOURCE_ROOT" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null); return 1; }

greeting(){
 clear_screen
 WIDTH="$(terminal_width)"
 printf 'Source      : %s\n' "$SOURCE_ROOT"
 printf 'Destination : %s\n' "$DEST_ROOT"
 printf '\n\n\n' # Artist is deliberately line 6.
 printf 'Artist:\n'
}

scan_frame(){
 local artist=$1 total=$2 albums=$3 current=$4
 # Scanning is allowed to repaint its temporary contents, but preserves the
 # greeting anchor at line 6.
 write_at "$ARTIST_ROW" "Artist: $artist"
 write_at 7 ''
 write_at 8 'Scanning...'
 write_at 9 "$(fit "$current")"
 write_at 10 ''
 write_at 11 "Found: $total tracks"
 write_at 12 "       $albums albums"
}

# Render the conversion frame once for each track. Subsequent polling updates
# only fields whose values actually change. Static labels are never redrawn.
conversion_static(){
 local artist=$1 an=$2 at=$3 tn=$4 tt=$5 file=$6 dur=$7
 WIDTH="$(terminal_width)"
 write_at "$ARTIST_ROW" "Artist: $artist > Album $an/$at > Track $tn/$tt >"
 write_at 7 "$(fit "$file")"
 write_at 9 'Encoding...'
 write_at 12 "Track Duration:  $dur"
 write_at 15 ''
}
conversion_dynamic(){
 local pct=$1 overall=$2 bitrate=$3 size=$4 elapsed=$5 eta=$6
 write_bar "$CONVERSION_BAR_ROW" "$pct"
 write_at "$BITRATE_ROW" "Bitrate:         $bitrate"
 write_at "$SIZE_ROW" "Size:            $size"
 write_at "$ELAPSED_ROW" "Elapsed:         $elapsed"
 write_at "$ETA_ROW" "ETA:             $eta"
 write_bar "$OVERALL_BAR_ROW" "$overall"
 write_at "$OVERALL_TEXT_ROW" "$overall% Complete"
}

summary_frame(){
 local artist=$1 elapsed=$2 done=$3 total=$4 failed=$5 skipped=$6 embedded=$7 copied=$8 extras=$9 src=${10} dst=${11} reduced=${12} pct=${13}
 # Summary also anchors Artist on the same line 6 as greeting/conversion.
 WIDTH="$(terminal_width)"
 write_at "$ARTIST_ROW" "Artist: $artist"
 write_at 7 ''
 write_at 8 "$elapsed elapsed"
 write_at 9 "> 100% [$done/$total]"
 write_at 10 "> [$failed] failed ; [$skipped] skipped"
 write_at 11 "> [$embedded/$total] images embedded"
 write_at 12 "> [$copied/$extras] extra files copied"
 write_at 13 ''
 write_at 14 "[$src] Source FLACs + extras"
 clear_row 15; move_to 15 1; summary_bar 100 "$WIDTH"
 write_at 16 "[$dst] Converted MP3s + extras"
 clear_row 17; move_to 17 1; summary_bar "$pct" "$WIDTH"
 write_at 18 "> $reduced reduced"
 write_at 20 '----------------------------------------'
 write_at 22 '[C] Convert another artist'
 write_at 23 '[Q] Quit'
 if [[ -s "$LAST_ERROR_LOG" ]]; then write_at 24 '[V] View error log'; else clear_row 24; fi
}

convert_track(){
 local src=$1 dst=$2 dur_us=$3 artist=$4 an=$5 at=$6 tn=$7 tt=$8 before=$9 start=${10} log=${11}
 local pfile efile pid status out_us pct overall bitrate size elapsed eta done_units dur name current_bytes total_bytes
 pfile=$(mktemp); efile=$(mktemp); dur=$(hdur "$(duration "$src")"); name=${src##*/}; mkdir -p "${dst%/*}"
 total_bytes=$(awk -v us="$dur_us" 'BEGIN{printf "%.0f",(us/1000000)*256000/8+2048}')
 ((total_bytes<1))&&total_bytes=1

 ffmpeg -hide_banner -loglevel error -nostats -nostdin -y -i "$src" -map 0:a:0 -map 0:v? -map_metadata 0 -c:a libmp3lame -b:a 256k -c:v mjpeg -id3v2_version 3 -write_id3v1 1 -progress "$pfile" "$dst" 2>"$efile" &
 pid=$!
 conversion_static "$artist" "$an" "$at" "$tn" "$tt" "$name" "$dur"

 while :; do
   current_bytes=$(size_of "$dst")
   pct=$((current_bytes*100/total_bytes)); ((pct>99))&&pct=99
   # Output size is the primary live conversion metric. ffmpeg timing is not
   # used to manufacture progress when the file itself has not grown.
   out_us=$(awk -F= '/^out_time_us=/{v=$2} END{print v+0}' "$pfile" 2>/dev/null); [[ "$out_us" =~ ^[0-9]+$ ]]||out_us=0
   if ((current_bytes>0 && out_us>0 && dur_us>0 && pct==0)); then
     pct=$((out_us*100/dur_us)); ((pct>99))&&pct=99
   fi
   overall=$(( (before*100+pct)/tt )); ((overall>100))&&overall=100
   bitrate=$(awk -F= '/^bitrate=/{v=$2} END{print v}' "$pfile" 2>/dev/null); [[ -n "$bitrate" ]]||bitrate='256 kb/s'
   size="$(hsize "$current_bytes") / $(hsize "$total_bytes")"
   elapsed=$(( $(date +%s)-start )); done_units=$((before*100+pct)); eta=0; ((done_units>0))&&eta=$((elapsed*(tt*100-done_units)/done_units))
   conversion_dynamic "$pct" "$overall" "$bitrate" "$size" "$(hdur "$elapsed")" "$(hdur "$eta")"
   if ! kill -0 "$pid" 2>/dev/null; then wait "$pid"; status=$?; break; fi
   sleep .20
 done

 if ((status==0)); then
   pct=100; overall=$(( (before*100+100)/tt )); ((overall>100))&&overall=100
   bitrate=$(awk -F= '/^bitrate=/{v=$2} END{print v}' "$pfile" 2>/dev/null); [[ -n "$bitrate" ]]||bitrate='256 kb/s'
   current_bytes=$(size_of "$dst"); size="$(hsize "$current_bytes") / $(hsize "$total_bytes")"; elapsed=$(( $(date +%s)-start )); eta=0
   conversion_dynamic 100 "$overall" "$bitrate" "$size" "$(hdur "$elapsed")" "$(hdur "$eta")"
 else
   printf 'FILE: %s\n' "$src" >>"$log"; cat "$efile" >>"$log"; printf '\n' >>"$log"; rm -f "$dst"
 fi
 rm -f "$pfile" "$efile"; return "$status"
}

run_artist(){
 local artist=$1 dir=$2 out="$DEST_ROOT/$artist" file rel album dst an dur_us start elapsed src_bytes=0 dst_bytes=0
 local -a tracks=() extras=(); local -A albums=() album_no=()
 local total=0 album_total=0 done=0 failed=0 skipped=0 embedded=0 copied=0 pct reduced
 mkdir -p "$out"
 while IFS= read -r -d '' file; do tracks+=("$file"); done < <(find "$dir" -type f -iname '*.flac' -print0|sort -z)
 total=${#tracks[@]}; ((total>0))||{ clear_screen; printf '\n\n\n\n\nArtist: %s\n\nNo FLAC tracks found.\n' "$artist"; return; }
 for file in "${tracks[@]}"; do rel=${file#"$dir"/}; album=${rel%/*}; [[ "$album" == "$rel" ]]&&album=Singles; [[ -n "${albums[$album]+x}" ]]||{ album_total=$((album_total+1)); albums[$album]=1; album_no[$album]=$album_total; }; src_bytes=$((src_bytes+$(size_of "$file"))); done
 while IFS= read -r -d '' file; do extras+=("$file"); src_bytes=$((src_bytes+$(size_of "$file"))); done < <(find "$dir" -type f ! -iname '*.flac' -print0|sort -z)
 LAST_ERROR_LOG="$out/.flac2mp3-errors.log"; : >"$LAST_ERROR_LOG"
 for file in "${tracks[@]}"; do scan_frame "$artist" "$total" "$album_total" "${file##*/}"; sleep .02; done
 start=$(date +%s)
 for ((i=0;i<total;i++)); do
   file=${tracks[$i]}; rel=${file#"$dir"/}; album=${rel%/*}; [[ "$album" == "$rel" ]]&&album=Singles; an=${album_no[$album]}; dst="$out/${rel%.*}.mp3"; mkdir -p "${dst%/*}"
   if [[ -f "$dst" ]]; then skipped=$((skipped+1)); continue; fi
   dur_us=$(duration_us "$file")
   if convert_track "$file" "$dst" "$dur_us" "$artist" "$an" "$album_total" "$((i+1))" "$total" "$((done+skipped))" "$start" "$LAST_ERROR_LOG"; then done=$((done+1)); cover "$file"&&embedded=$((embedded+1)); else failed=$((failed+1)); fi
 done
 for file in "${extras[@]}"; do rel=${file#"$dir"/}; dst="$out/$rel"; mkdir -p "${dst%/*}"; [[ -e "$dst" ]]||{ cp -p "$file" "$dst"&&copied=$((copied+1)); }; done
 while IFS= read -r -d '' file; do dst_bytes=$((dst_bytes+$(size_of "$file"))); done < <(find "$out" -type f ! -name '.flac2mp3-errors.log' -print0)
 ((src_bytes>0))&&pct=$((dst_bytes*100/src_bytes))||pct=0; ((pct>100))&&pct=100; reduced=$((src_bytes-dst_bytes)); ((reduced<0))&&reduced=0; elapsed=$(( $(date +%s)-start )); summary_frame "$artist" "$(hdur "$elapsed")" "$((done+skipped))" "$total" "$failed" "$skipped" "$embedded" "$copied" "${#extras[@]}" "$(hsize "$src_bytes")" "$(hsize "$dst_bytes")" "$(hsize "$reduced")" "$pct"
}

main(){
 hide_cursor
 while true; do
   greeting
   move_to "$ARTIST_ROW" 1
   IFS= read -r artist
   [[ -z "$artist" ]]&&continue
   if ! dir=$(find_artist "$artist"); then clear_screen; printf 'Source      : %s\nDestination : %s\n\n\n\nArtist:\n\n%s not found.\n\nPress Enter to continue.' "$SOURCE_ROOT" "$DEST_ROOT" "$artist"; read -r _; continue; fi
   run_artist "$artist" "$dir"
   while true; do IFS= read -r -n1 choice; printf '\n'; case "${choice^^}" in C) break;; Q|'') return;; V) clear_screen; printf 'Error Log\n\n'; cat "$LAST_ERROR_LOG"; printf '\nPress Enter to return.'; read -r _;; esac; done
 done
}
main "$@"
