#!/usr/bin/env bash
set -u
set -o pipefail

# Refactored/corrected frozen UI candidate.
# The original flac2mp3.sh remains untouched.

SOURCE_ROOT="${SOURCE_ROOT:-$HOME/storage/shared/Music/FLAC}"
DEST_ROOT="${DEST_ROOT:-$HOME/storage/shared/Music/MP3}"
LAST_ERROR_LOG=""

need_cmd() { command -v "$1" >/dev/null 2>&1 || { printf 'Missing dependency: %s\n' "$1" >&2; exit 1; }; }
for cmd in ffmpeg ffprobe find sort awk mktemp stat date tput; do need_cmd "$cmd"; done

WIDTH="$(tput cols 2>/dev/null || printf '80')"
[[ "$WIDTH" =~ ^[0-9]+$ ]] || WIDTH=80
((WIDTH < 60)) && WIDTH=60

clear_screen() { printf '\033[2J\033[H'; }
hide_cursor() { printf '\033[?25l'; }
show_cursor() { printf '\033[?25h'; }
trap 'show_cursor; printf "\n"' EXIT INT TERM

hsize() { awk -v b="${1:-0}" 'BEGIN{split("B KiB MiB GiB TiB",u);i=1;while(b>=1024&&i<5){b/=1024;i++};if(i==1)printf "%.0f %s",b,u[i];else printf "%.1f %s",b,u[i]}' ; }
hdur() { awk -v s="${1:-0}" 'BEGIN{s+=0;h=int(s/3600);m=int((s%3600)/60);x=int(s%60);if(h>0)printf "%02dh%02dm%02ds",h,m,x;else printf "%02dm%02ds",m,x}' ; }
size_of() { stat -c '%s' "$1" 2>/dev/null || stat -f '%z' "$1" 2>/dev/null || printf 0; }
seconds() { awk -v s="${1:-0}" 'BEGIN{if(s==""||s=="N/A")s=0;printf "%.3f",s+0}'; }

# ASCII-only progress bars: no Unicode block/box-drawing glyphs and no color.
progress_bar() {
    local pct="$1" width="$2" body filled empty
    ((pct<0))&&pct=0; ((pct>100))&&pct=100
    body=$((width-5)); ((body<10))&&body=10
    filled=$((body*pct/100)); empty=$((body-filled))
    printf '%*s' "$filled" '' | tr ' ' '#'
    printf '%*s' "$empty" '' | tr ' ' '-'
    printf '%3d%%' "$pct"
}

summary_bar() {
    local pct="$1" width="$2" body filled empty
    ((pct<0))&&pct=0; ((pct>100))&&pct=100
    # Summary bars intentionally reserve terminal columns for margins/labels.
    body=$((width-12)); ((body<20))&&body=20
    filled=$((body*pct/100)); empty=$((body-filled))
    printf '%*s' "$filled" '' | tr ' ' '#'
    printf '%*s' "$empty" '' | tr ' ' '.'
}

find_artist() {
    local wanted="$1" d base
    [[ -d "$SOURCE_ROOT/$wanted" ]] && { printf '%s\n' "$SOURCE_ROOT/$wanted"; return 0; }
    while IFS= read -r -d '' d; do
        base="${d##*/}"
        [[ "${base,,}" == "${wanted,,}" ]] && { printf '%s\n' "$d"; return 0; }
    done < <(find "$SOURCE_ROOT" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null)
    return 1
}

duration() { ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "$1" 2>/dev/null | seconds; }
duration_us() { awk -v s="$(duration "$1")" 'BEGIN{printf "%.0f",s*1000000}'; }
cover() { [[ "$(ffprobe -v error -select_streams v -show_entries stream=disposition.attached_pic -of default=nw=1:nk=1 "$1" 2>/dev/null)" == 1 ]]; }

greeting() {
    clear_screen
    printf 'Source      : %s\n' "$SOURCE_ROOT"
    printf 'Destination : %s\n\n' "$DEST_ROOT"
    printf 'Artist: '
}

scan_frame() {
    local artist="$1" total="$2" albums="$3" current="$4"
    clear_screen
    printf 'Artist: %s\n\n' "$artist"
    printf 'Scanning...\n'
    printf '%s\n\n' "$current"
    printf 'Found: %d tracks\n' "$total"
    printf '       %d albums\n' "$albums"
}

convert_frame() {
    local artist="$1" an="$2" at="$3" tn="$4" tt="$5" file="$6" pct="$7" overall="$8" bitrate="$9" size="${10}" dur="${11}" elapsed="${12}" eta="${13}"
    clear_screen
    printf 'Artist: %s > Album %d/%d > Track %d/%d >\n' "$artist" "$an" "$at" "$tn" "$tt"
    printf '%s\n' "$file"
    progress_bar "$pct" "$WIDTH"; printf '\n'
    printf 'Encoding...\n'
    printf 'Bitrate:         %s\n' "${bitrate:---}"
    printf 'Size:            %s\n' "${size:---}"
    printf 'Track Duration:  %s\n' "$dur"
    printf 'Elapsed:         %s\n' "$elapsed"
    printf 'ETA:             %s\n\n' "${eta:---}"
    progress_bar "$overall" "$WIDTH"; printf '\n'
    printf '%d%% Complete\n' "$overall"
}

summary_frame() {
    local artist="$1" elapsed="$2" done="$3" total="$4" failed="$5" skipped="$6" embedded="$7" copied="$8" extras="$9" src="${10}" dst="${11}" reduced="${12}" pct="${13}"
    clear_screen
    printf 'Artist: %s\n\n' "$artist"
    printf '%s elapsed\n' "$elapsed"
    printf '> 100%% [%d/%d]\n' "$done" "$total"
    printf '> [%d] failed ; [%d] skipped\n' "$failed" "$skipped"
    printf '> [%d/%d] images embedded\n' "$embedded" "$total"
    printf '> [%d/%d] extra files copied\n\n' "$copied" "$extras"
    printf '[%s] Source FLACs + extras\n' "$src"
    summary_bar 100 "$WIDTH"; printf '\n\n'
    printf '[%s] Converted MP3s + extras\n' "$dst"
    summary_bar "$pct" "$WIDTH"; printf '\n\n'
    printf '> %s reduced\n\n' "$reduced"
    printf '%s\n\n' '----------------------------------------'
    printf '[C] Convert another artist\n'
    printf '[Q] Quit\n'
    [[ -s "$LAST_ERROR_LOG" ]] && printf '[V] View error log\n'
}

convert_track() {
    local src="$1" dst="$2" dur_us="$3" artist="$4" an="$5" at="$6" tn="$7" tt="$8" before="$9" start="${10}" log="${11}"
    local pfile efile pid status out pct overall bitrate size elapsed eta dur name done_units
    pfile="$(mktemp)"; efile="$(mktemp)"; dur="$(hdur "$(duration "$src")")"; name="${src##*/}"
    mkdir -p "${dst%/*}"
    ffmpeg -hide_banner -loglevel error -nostats -nostdin -y -i "$src" -map 0:a:0 -map 0:v? -map_metadata 0 -c:a libmp3lame -q:a 2 -c:v mjpeg -id3v2_version 3 -write_id3v1 1 -progress "$pfile" "$dst" 2>"$efile" &
    pid=$!
    while kill -0 "$pid" 2>/dev/null; do
        out="$(awk -F= '$1=="out_time_us"{v=$2}END{print v+0}' "$pfile")"; [[ "$out" =~ ^[0-9]+$ ]] || out=0
        ((dur_us>0)) && pct=$((out*100/dur_us)) || pct=0; ((pct>100))&&pct=100
        overall=$(( (before*100+pct)/tt ))
        bitrate="$(awk -F= '$1=="bitrate"{v=$2}END{print v}' "$pfile")"
        size="$(hsize "$(size_of "$dst")")"
        elapsed=$(( $(date +%s)-start )); eta=0; done_units=$((before*100+pct)); ((done_units>0))&&eta=$((elapsed*(tt*100-done_units)/done_units))
        convert_frame "$artist" "$an" "$at" "$tn" "$tt" "$name" "$pct" "$overall" "${bitrate:---}" "$size" "$dur" "$(hdur "$elapsed")" "$(hdur "$eta")"
        sleep .15
    done
    wait "$pid"; status=$?
    if ((status!=0)); then printf 'FILE: %s\n' "$src" >> "$log"; cat "$efile" >> "$log"; printf '\n' >> "$log"; rm -f "$dst"; fi
    rm -f "$pfile" "$efile"
    return "$status"
}

run_artist() {
    local artist="$1" dir="$2" out="$DEST_ROOT/$artist" file rel album dst an dur_us start elapsed src_bytes=0 dst_bytes=0
    local -a tracks=() extras=()
    local -A albums=() album_no=()
    local total=0 album_total=0 done=0 failed=0 skipped=0 embedded=0 copied=0 pct reduced
    mkdir -p "$out"
    while IFS= read -r -d '' file; do tracks+=("$file"); done < <(find "$dir" -type f -iname '*.flac' -print0 | sort -z)
    total=${#tracks[@]}; ((total>0)) || { clear_screen; printf 'Artist: %s\n\nNo FLAC tracks found.\n' "$artist"; return; }
    for file in "${tracks[@]}"; do
        rel="${file#"$dir"/}"; album="${rel%/*}"; [[ "$album" == "$rel" ]]&&album=Singles
        [[ -n "${albums[$album]+x}" ]] || { album_total=$((album_total+1)); albums[$album]=1; album_no[$album]=$album_total; }
        src_bytes=$((src_bytes+$(size_of "$file")))
    done
    while IFS= read -r -d '' file; do extras+=("$file"); src_bytes=$((src_bytes+$(size_of "$file"))); done < <(find "$dir" -type f ! -iname '*.flac' -print0 | sort -z)
    LAST_ERROR_LOG="$out/.flac2mp3-errors.log"; : > "$LAST_ERROR_LOG"

    for file in "${tracks[@]}"; do scan_frame "$artist" "$total" "$album_total" "${file##*/}"; sleep .02; done
    start="$(date +%s)"
    for ((i=0;i<total;i++)); do
        file="${tracks[$i]}"; rel="${file#"$dir"/}"; album="${rel%/*}"; [[ "$album" == "$rel" ]]&&album=Singles; an="${album_no[$album]}"; dst="$out/${rel%.*}.mp3"; mkdir -p "${dst%/*}"
        if [[ -f "$dst" ]]; then skipped=$((skipped+1)); continue; fi
        dur_us="$(duration_us "$file")"
        if convert_track "$file" "$dst" "$dur_us" "$artist" "$an" "$album_total" "$((i+1))" "$total" "$((done+skipped))" "$start" "$LAST_ERROR_LOG"; then done=$((done+1)); cover "$file" && embedded=$((embedded+1)); else failed=$((failed+1)); fi
    done
    for file in "${extras[@]}"; do rel="${file#"$dir"/}"; dst="$out/$rel"; mkdir -p "${dst%/*}"; [[ -e "$dst" ]] || { cp -p "$file" "$dst" && copied=$((copied+1)); }; done
    while IFS= read -r -d '' file; do dst_bytes=$((dst_bytes+$(size_of "$file"))); done < <(find "$out" -type f ! -name '.flac2mp3-errors.log' -print0)
    ((src_bytes>0))&&pct=$((dst_bytes*100/src_bytes))||pct=0; ((pct>100))&&pct=100; reduced=$((src_bytes-dst_bytes)); ((reduced<0))&&reduced=0; elapsed=$(( $(date +%s)-start ))
    summary_frame "$artist" "$(hdur "$elapsed")" "$((done+skipped))" "$total" "$failed" "$skipped" "$embedded" "$copied" "${#extras[@]}" "$(hsize "$src_bytes")" "$(hsize "$dst_bytes")" "$(hsize "$reduced")" "$pct"
}

main() {
    hide_cursor
    while true; do
        greeting; IFS= read -r artist; [[ -z "$artist" ]]&&continue
        if ! dir="$(find_artist "$artist")"; then clear_screen; printf 'Artist: %s\n\nArtist not found.\n\nPress Enter to continue.' "$artist"; read -r _; continue; fi
        run_artist "$artist" "$dir"
        while true; do IFS= read -r -n 1 choice; printf '\n'; case "${choice^^}" in C) break;; Q|'') return;; V) clear_screen; printf 'Error Log\n\n'; cat "$LAST_ERROR_LOG"; printf '\nPress Enter to return.'; read -r _;; esac; done
    done
}
main "$@"
