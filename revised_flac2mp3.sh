#!/usr/bin/env bash
set -u
set -o pipefail
SOURCE_ROOT="${SOURCE_ROOT:-$HOME/storage/shared/Music/FLAC}"
DEST_ROOT="${DEST_ROOT:-$HOME/storage/shared/Music/MP3}"
LAST_ERROR_LOG=""
for cmd in ffmpeg ffprobe find sort awk mktemp stat date tput; do command -v "$cmd" >/dev/null 2>&1 || { printf 'Missing dependency: %s\n' "$cmd" >&2; exit 1; }; done

W(){ local w; w="$(tput cols 2>/dev/null || echo 80)"; [[ $w =~ ^[0-9]+$ ]]||w=80; ((w<20))&&w=20; printf '%s' "$w"; }
WIDTH="$(W)"; ARTIST_ROW=4; BAR_ROW=7; BITRATE_ROW=9; SIZE_ROW=10; DUR_ROW=11; ELAPSED_ROW=12; ETA_ROW=13; OVERALL_BAR_ROW=15; OVERALL_TEXT_ROW=17
clear_screen(){ printf '\033[2J\033[H'; }
hide(){ printf '\033[?25l'; }; show(){ printf '\033[?25h'; }; trap 'show; printf "\n"' EXIT INT TERM
move(){ printf '\033[%d;%dH' "$1" "$2"; }; clr(){ move "$1" 1; printf '\033[2K'; }
put(){ local r=${1:-1} t=${2-}; clr "$r"; move "$r" 1; printf '%s' "$t"; }
val(){ local r=$1 c=$2 width=$3 t=${4-}; move "$r" "$c"; printf "%-${width}s" "${t:0:width}"; }
hsize(){ awk -v b="${1:-0}" 'BEGIN{split("B KiB MiB GiB TiB",u);i=1;while(b>=1024&&i<5){b/=1024;i++};printf(i==1?"%.0f %s":"%.1f %s",b,u[i])}'; }
hdur(){ awk -v s="${1:-0}" 'BEGIN{h=int(s/3600);m=int((s%3600)/60);x=int(s%60);if(h)printf "%02dh%02dm%02ds",h,m,x;else printf "%02dm%02ds",m,x}'; }
size_of(){ stat -c '%s' "$1" 2>/dev/null || stat -f '%z' "$1" 2>/dev/null || echo 0; }
duration(){ ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "$1" 2>/dev/null; }
duration_us(){ awk -v s="$(duration "$1")" 'BEGIN{printf "%.0f",(s+0)*1000000}'; }
cover(){ [[ "$(ffprobe -v error -select_streams v -show_entries stream=disposition.attached_pic -of default=nw=1:nk=1 "$1" 2>/dev/null)" == 1 ]]; }
fit(){ local s=${1-} w=${2:-$WIDTH}; (( ${#s}>w ))&&printf '%s...' "${s:0:w-3}"||printf '%s' "$s"; }

# Plain ASCII bar. It intentionally has no percentage suffix; the percentage
# is rendered as a separate field below/alongside the bar.
bar(){ local pct=$1 width=$2 inner filled empty; ((pct<0))&&pct=0; ((pct>100))&&pct=100; inner=$((width)); ((inner<1))&&inner=1; filled=$((inner*pct/100)); empty=$((inner-filled)); printf '%*s' "$filled" ''|tr ' ' '#'; printf '%*s' "$empty" ''|tr ' ' '-'; }
summary_bar(){ local pct=$1 width=$2 f e; ((pct<0))&&pct=0; ((pct>100))&&pct=100; f=$((width*pct/100)); e=$((width-f)); printf '%*s' "$f" ''|tr ' ' '#'; printf '%*s' "$e" ''|tr ' ' '-'; }

clear_transition(){ for r in 1 2 3; do clr "$r"; done; }
greeting(){ clear_screen; WIDTH="$(W)"; put 1 "Source      : $SOURCE_ROOT"; put 2 "Destination : $DEST_ROOT"; put 3 ''; put "$ARTIST_ROW" 'Artist:'; move "$ARTIST_ROW" 8; show; }
scan_frame(){ local artist=${1-} total=${2-0} albums=${3-0} current=${4-}; put "$ARTIST_ROW" "Artist: $artist"; put 5 ''; put 6 'Scanning...'; put 7 "$(fit "$current")"; put 8 ''; put 9 "Found: $total tracks"; put 10 "       $albums albums"; }
conversion_static(){
 local artist=${1-} an=${2-} at=${3-} tn=${4-} tt=${5-0} file=${6-} dur=${7-}
 local context="Artist: $artist > Album $an/$at > Track $tn/$tt >"
 put "$ARTIST_ROW" "$(fit "$context")"
 put 5 "$(fit "$file")"
 put 6 ''
 put 7 ''
 put 8 '0% Complete'
 put 9 'Bitrate: '
 put 10 'Size: '
 put 11 "Track Duration:  $dur"
 put 12 'Elapsed: '
 put 13 'ETA: '
 put 14 ''
 put 15 ''
 put 16 ''
 put 17 'Overall 0% Complete'
}
conversion_dynamic(){
 local pct=${1:-0} overall=${2:-0} bitrate=${3:---} size=${4:---} elapsed=${5:---} eta=${6:---}
 clr "$BAR_ROW"; move "$BAR_ROW" 1; bar "$pct" "$WIDTH"
 val "$BAR_ROW" $((WIDTH-7)) 7 "${pct}% Complete"
 # Keep the label fixed and update only the value area.
 val "$BITRATE_ROW" 18 24 '256 kb/s'
 val "$SIZE_ROW" 18 32 "$size"
 val "$ELAPSED_ROW" 10 12 "$elapsed"
 val "$ETA_ROW" 6 12 "$eta"
 clr "$OVERALL_BAR_ROW"; move "$OVERALL_BAR_ROW" 1; summary_bar "$overall" "$WIDTH"
 val "$OVERALL_TEXT_ROW" 1 "$WIDTH" "Overall ${overall}% Complete"
}
summary_frame(){ local artist=${1-} elapsed=${2-} done=${3-0} total=${4-0} failed=${5-0} skipped=${6-0} embedded=${7-0} copied=${8-0} extras=${9-0} src=${10-} dst=${11-} reduced=${12-} pct=${13-0}; clear_transition; put "$ARTIST_ROW" "Artist: $artist"; put 5 ''; put 6 "$elapsed elapsed"; put 7 "> 100% [$done/$total]"; put 8 "> [$failed] failed ; [$skipped] skipped"; put 9 "> [$embedded/$total] images embedded"; put 10 "> [$copied/$extras] extra files copied"; put 11 ''; put 12 "[$src] Source FLACs + extras"; clr 13; move 13 1; summary_bar 100 "$WIDTH"; put 14 "[$dst] Converted MP3s + extras"; clr 15; move 15 1; summary_bar "$pct" "$WIDTH"; put 16 "> $reduced reduced"; put 18 '----------------------------------------'; put 20 '[C] Convert another artist'; put 21 '[Q] Quit'; [[ -s "$LAST_ERROR_LOG" ]]&&put 22 '[V] View error log'||clr 22; }

find_artist(){ local wanted=$1 d base; [[ -d "$SOURCE_ROOT/$wanted" ]]&&{ printf '%s\n' "$SOURCE_ROOT/$wanted"; return; }; while IFS= read -r -d '' d; do base=${d##*/}; [[ "${base,,}" == "${wanted,,}" ]]&&{ printf '%s\n' "$d"; return; }; done < <(find "$SOURCE_ROOT" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null); return 1; }

convert_track(){
 local src=$1 dst=$2 dur_us=$3 artist=$4 an=$5 at=$6 tn=$7 tt=$8 before=$9 start=${10} log=${11}
 local pfile efile pid status pct overall size elapsed eta current_bytes total_bytes out_us time_pct dur name
 pfile=$(mktemp); efile=$(mktemp); dur=$(hdur "$(duration "$src")"); name=${src##*/}; mkdir -p "${dst%/*}"
 total_bytes=$(awk -v us="$dur_us" 'BEGIN{printf "%.0f",(us/1000000)*256000/8+2048}'); ((total_bytes<1))&&total_bytes=1
 conversion_static "$artist" "$an" "$at" "$tn" "$tt" "$name" "$dur"
 ffmpeg -hide_banner -loglevel error -nostats -nostdin -y -i "$src" -map 0:a:0 -map 0:v? -map_metadata 0 -c:a libmp3lame -b:a 256k -c:v mjpeg -id3v2_version 3 -write_id3v1 1 -progress "$pfile" "$dst" 2>"$efile" & pid=$!
 while :; do
  current_bytes=$(size_of "$dst"); pct=$((current_bytes*100/total_bytes)); ((pct>99))&&pct=99
  out_us=$(awk -F= '/^out_time_us=/{v=$2} END{print v+0}' "$pfile" 2>/dev/null); [[ $out_us =~ ^[0-9]+$ ]]||out_us=0
  if ((pct==0&&out_us>0&&dur_us>0)); then time_pct=$((out_us*100/dur_us)); ((time_pct>99))&&time_pct=99; pct=$time_pct; fi
  overall=$(( (before*100+pct)/tt )); ((overall>100))&&overall=100
  size="$(hsize "$current_bytes") / $(hsize "$total_bytes")"; elapsed=$(( $(date +%s)-start )); eta=0; ((before*100+pct>0))&&eta=$((elapsed*(tt*100-before*100-pct)/(before*100+pct)))
  conversion_dynamic "$pct" "$overall" '256 kb/s' "$size" "$(hdur "$elapsed")" "$(hdur "$eta")"
  if ! kill -0 "$pid" 2>/dev/null; then wait "$pid"; status=$?; break; fi
  sleep .20
 done
 if ((status==0)); then current_bytes=$(size_of "$dst"); elapsed=$(( $(date +%s)-start )); conversion_dynamic 100 "$(( (before*100+100)/tt ))" '256 kb/s' "$(hsize "$current_bytes") / $(hsize "$total_bytes")" "$(hdur "$elapsed")" '00m00s'; else printf 'FILE: %s\n' "$src" >>"$log"; cat "$efile" >>"$log"; printf '\n' >>"$log"; rm -f "$dst"; fi
 rm -f "$pfile" "$efile"; return "$status"
}
run_artist(){
 local artist=$1 dir=$2 out="$DEST_ROOT/$artist" file rel album dst an dur_us start elapsed src_bytes=0 dst_bytes=0
 local -a tracks=() extras=(); local -A albums=() album_no=(); local total=0 album_total=0 done=0 failed=0 skipped=0 embedded=0 copied=0 pct reduced
 mkdir -p "$out"; while IFS= read -r -d '' file; do tracks+=("$file"); done < <(find "$dir" -type f -iname '*.flac' -print0|sort -z); total=${#tracks[@]}; ((total>0))||{ clear_screen; printf '\n\n\nArtist: %s\n\nNo FLAC tracks found.\n' "$artist"; return; }
 for file in "${tracks[@]}"; do rel=${file#"$dir"/}; album=${rel%/*}; [[ "$album" == "$rel" ]]&&album=Singles; [[ -n ${albums[$album]+x} ]]||{ album_total=$((album_total+1)); albums[$album]=1; album_no[$album]=$album_total; }; src_bytes=$((src_bytes+$(size_of "$file"))); done
 while IFS= read -r -d '' file; do extras+=("$file"); src_bytes=$((src_bytes+$(size_of "$file"))); done < <(find "$dir" -type f ! -iname '*.flac' -print0|sort -z)
 LAST_ERROR_LOG="$out/.flac2mp3-errors.log"; : >"$LAST_ERROR_LOG"; clear_transition
 for file in "${tracks[@]}"; do scan_frame "$artist" "$total" "$album_total" "${file##*/}"; sleep .02; done
 start=$(date +%s)
 for ((i=0;i<total;i++)); do file=${tracks[$i]}; rel=${file#"$dir"/}; album=${rel%/*}; [[ "$album" == "$rel" ]]&&album=Singles; an=${album_no[$album]}; dst="$out/${rel%.*}.mp3"; mkdir -p "${dst%/*}"; if [[ -f "$dst" ]]; then skipped=$((skipped+1)); continue; fi; dur_us=$(duration_us "$file"); if convert_track "$file" "$dst" "$dur_us" "$artist" "$an" "$album_total" "$((i+1))" "$total" "$((done+skipped))" "$start" "$LAST_ERROR_LOG"; then done=$((done+1)); cover "$file"&&embedded=$((embedded+1)); else failed=$((failed+1)); fi; done
 for file in "${extras[@]}"; do rel=${file#"$dir"/}; dst="$out/$rel"; mkdir -p "${dst%/*}"; [[ -e "$dst" ]]||{ cp -p "$file" "$dst"&&copied=$((copied+1)); }; done
 while IFS= read -r -d '' file; do dst_bytes=$((dst_bytes+$(size_of "$file"))); done < <(find "$out" -type f ! -name '.flac2mp3-errors.log' -print0); ((src_bytes>0))&&pct=$((dst_bytes*100/src_bytes))||pct=0; ((pct>100))&&pct=100; reduced=$((src_bytes-dst_bytes)); ((reduced<0))&&reduced=0; elapsed=$(( $(date +%s)-start )); summary_frame "$artist" "$(hdur "$elapsed")" "$((done+skipped))" "$total" "$failed" "$skipped" "$embedded" "$copied" "${#extras[@]}" "$(hsize "$src_bytes")" "$(hsize "$dst_bytes")" "$(hsize "$reduced")" "$pct"
}
main(){ hide; while true; do greeting; IFS= read -r artist; show; [[ -z "$artist" ]]&&continue; hide; if ! dir=$(find_artist "$artist"); then clear_screen; printf 'Source      : %s\nDestination : %s\n\nArtist:\n\n%s not found.\n\nPress Enter to continue.' "$SOURCE_ROOT" "$DEST_ROOT" "$artist"; read -r _; continue; fi; run_artist "$artist" "$dir"; while true; do IFS= read -r -n1 choice; printf '\n'; case "${choice^^}" in C) break;; Q|'') return;; V) clear_screen; printf 'Error Log\n\n'; cat "$LAST_ERROR_LOG"; printf '\nPress Enter to return.'; read -r _;; esac; done; done; }
main "$@"
