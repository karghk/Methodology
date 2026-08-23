#!/usr/bin/env bash
set -u
set -o pipefail

# Refactored/corrected UI implementation.
# The original flac2mp3.sh is intentionally untouched.

SOURCE_ROOT="${SOURCE_ROOT:-$HOME/storage/shared/Music/FLAC}"
DEST_ROOT="${DEST_ROOT:-$HOME/storage/shared/Music/MP3}"
LAST_ERROR_LOG=""

ESC=$'\033'
RESET=$'\033[0m'
DIM=$'\033[2m'
YELLOW=$'\033[33m'
RED=$'\033[31m'
GREEN=$'\033[32m'

need_cmd() {
    command -v "$1" >/dev/null 2>&1 || {
        printf '%sMissing dependency: %s%s\n' "$RED" "$1" "$RESET" >&2
        exit 1
    }
}

for cmd in ffmpeg ffprobe find sort awk mktemp stat date tput; do need_cmd "$cmd"; done

term_width() {
    local w
    w="$(tput cols 2>/dev/null || printf '80')"
    [[ "$w" =~ ^[0-9]+$ ]] || w=80
    ((w < 60)) && w=60
    printf '%s' "$w"
}

WIDTH="$(term_width)"

clear_screen() {
    printf '%s[2J%s[H' "$ESC" "$ESC"
}

move_home() {
    printf '%s[H' "$ESC"
}

hide_cursor() { printf '%s[?25l' "$ESC"; }
show_cursor() { printf '%s[?25h' "$ESC"; }
trap 'show_cursor; printf "%s[0m%s[?25h\n" "$ESC" "$ESC"' EXIT INT TERM

repeat_char() {
    local n="$1" ch="$2"
    ((n <= 0)) && return
    printf '%*s' "$n" '' | tr ' ' "$ch"
}

rule() {
    repeat_char "$WIDTH" '─'
}

human_size() {
    awk -v b="${1:-0}" 'BEGIN { split("B KiB MiB GiB TiB",u); i=1; while(b>=1024&&i<5){b/=1024;i++}; if(i==1)printf "%.0f %s",b,u[i]; else printf "%.1f %s",b,u[i] }'
}

human_duration() {
    awk -v s="${1:-0}" 'BEGIN { s+=0; if(s<0)s=0; h=int(s/3600); m=int((s%3600)/60); x=int(s%60); if(h>0)printf "%02dh%02dm%02ds",h,m,x; else printf "%02dm%02ds",m,x }'
}

seconds() {
    awk -v s="${1:-0}" 'BEGIN {if(s==""||s=="N/A")s=0; printf "%.3f",s+0}'
}

file_size() {
    stat -c '%s' "$1" 2>/dev/null || stat -f '%z' "$1" 2>/dev/null || printf '0'
}

bar() {
    # Full-width conversion/progress bar. Percentage is kept outside the fill.
    local pct="$1" width="$2" inner filled empty
    ((pct<0)) && pct=0; ((pct>100)) && pct=100
    inner=$((width-7)); ((inner<10)) && inner=10
    filled=$((inner*pct/100)); empty=$((inner-filled))
    printf '['
    ((filled>0)) && repeat_char "$filled" '█'
    ((empty>0)) && repeat_char "$empty" '─'
    printf '] %3d%%' "$pct"
}

storage_bar() {
    # Storage bars use a different visual grammar from conversion progress.
    local pct="$1" width="$2" inner filled empty
    ((pct<0)) && pct=0; ((pct>100)) && pct=100
    inner=$((width-7)); ((inner<10)) && inner=10
    filled=$((inner*pct/100)); empty=$((inner-filled))
    printf '['
    ((filled>0)) && repeat_char "$filled" '■'
    ((empty>0)) && repeat_char "$empty" '·'
    printf '] %3d%%' "$pct"
}

find_artist_dir() {
    local wanted="$1" candidate base
    [[ -d "$SOURCE_ROOT/$wanted" ]] && { printf '%s\n' "$SOURCE_ROOT/$wanted"; return 0; }
    while IFS= read -r -d '' candidate; do
        base="${candidate##*/}"
        if [[ "${base,,}" == "${wanted,,}" ]]; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done < <(find "$SOURCE_ROOT" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null)
    return 1
}

track_duration() {
    ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "$1" 2>/dev/null | seconds
}

track_duration_us() {
    awk -v s="$(track_duration "$1")" 'BEGIN{printf "%.0f",s*1000000}'
}

has_cover() {
    [[ "$(ffprobe -v error -select_streams v -show_entries stream=disposition.attached_pic -of default=nw=1:nk=1 "$1" 2>/dev/null)" == "1" ]]
}

frame_greeting() {
    clear_screen
    printf 'FLAC → MP3 Converter\n\n'
    printf 'Source      : %s\n' "$SOURCE_ROOT"
    printf 'Destination : %s\n\n' "$DEST_ROOT"
    printf 'Artist: '
}

frame_scan() {
    local artist="$1" total_tracks="$2" total_albums="$3" current="$4"
    clear_screen
    printf 'FLAC → MP3 Converter\n\n'
    printf 'Artist: %s\n\n' "$artist"
    printf 'Library Scan\n\n'
    printf 'Scanning...\n'
    printf 'Current file: %-*s\n\n' "$((WIDTH-14))" "${current##*/}"
    printf 'Found: %d tracks\n' "$total_tracks"
    printf '       %d albums\n\n' "$total_albums"
    rule
}

frame_convert() {
    local artist="$1" album_no="$2" album_total="$3" track_no="$4" track_total="$5" track="$6"
    local track_pct="$7" overall_pct="$8" bitrate="$9" size="${10}" duration="${11}" elapsed="${12}" eta="${13}"
    clear_screen
    printf 'FLAC → MP3 Converter\n\n'
    printf 'Artist: %s > Album %d/%d > Track %d/%d >\n' "$artist" "$album_no" "$album_total" "$track_no" "$track_total"
    printf '\n%s\n\n' "$track"
    printf 'Encoding...\n'
    printf 'Bitrate:         %s\n' "${bitrate:---}"
    printf 'Size:            %s\n' "${size:---}"
    printf 'Track Duration:  %s\n' "$duration"
    printf 'Elapsed:         %s\n' "$elapsed"
    printf 'ETA:             %s\n\n' "${eta:---}"
    bar "$track_pct" "$WIDTH"; printf '\n'
    printf '\n'
    printf 'Overall Progress\n'
    bar "$overall_pct" "$WIDTH"; printf '\n'
}

frame_summary() {
    local artist="$1" elapsed="$2" done="$3" total="$4" failed="$5" skipped="$6" embedded="$7" copied="$8" extras="$9"
    local src_size="${10}" dst_size="${11}" reduction="${12}" dst_pct="${13}"
    clear_screen
    printf 'FLAC → MP3 Converter\n\n'
    printf 'Artist: %s\n\n' "$artist"
    printf '%s elapsed\n' "$elapsed"
    printf '> 100%% [%d/%d]\n' "$done" "$total"
    printf '> [%d] failed ; [%d] skipped\n' "$failed" "$skipped"
    printf '> [%d/%d] images embedded\n' "$embedded" "$total"
    printf '> [%d/%d] extra files copied\n\n' "$copied" "$extras"
    printf '[%s] Source FLACs + extras\n' "$src_size"
    storage_bar 100 "$WIDTH"; printf '\n\n'
    printf '[%s] Converted MP3s + extras\n' "$dst_size"
    storage_bar "$dst_pct" "$WIDTH"; printf '\n\n'
    printf '> %s reduced\n\n' "$reduction"
    rule
    printf '\n[C] Convert another artist\n[Q] Quit\n'
    [[ -s "$LAST_ERROR_LOG" ]] && printf '[V] View error log\n'
}

convert_track() {
    local src="$1" dst="$2" duration_us="$3" artist="$4" album_no="$5" album_total="$6" track_no="$7" track_total="$8" overall_before="$9" start_epoch="${10}" error_log="${11}"
    local progress_tmp error_tmp pid status out_us pct overall bitrate size elapsed eta duration track_name
    progress_tmp="$(mktemp)"; error_tmp="$(mktemp)"
    duration="$(human_duration "$(track_duration "$src")")"
    track_name="${src##*/}"
    mkdir -p "${dst%/*}"

    ffmpeg -hide_banner -loglevel error -nostats -nostdin -y \
        -i "$src" -map 0:a:0 -map 0:v? -map_metadata 0 \
        -c:a libmp3lame -q:a 2 -c:v mjpeg \
        -id3v2_version 3 -write_id3v1 1 \
        -progress "$progress_tmp" "$dst" 2>"$error_tmp" &
    pid=$!

    while kill -0 "$pid" 2>/dev/null; do
        out_us="$(awk -F= '$1=="out_time_us"{v=$2}END{print v+0}' "$progress_tmp")"
        [[ "$out_us" =~ ^[0-9]+$ ]] || out_us=0
        if ((duration_us>0)); then pct=$((out_us*100/duration_us)); else pct=0; fi
        ((pct>100)) && pct=100
        overall=$(( (overall_before*100+ (pct+50)/100) * 100 / track_total )) 2>/dev/null || overall="$overall_before"
        # Exact integer overall calculation without floating arithmetic.
        overall=$(( (overall_before*100 + pct) / track_total ))
        bitrate="$(awk -F= '$1=="bitrate"{v=$2}END{print v}' "$progress_tmp")"
        size="$(human_size "$(file_size "$dst")")"
        elapsed=$(( $(date +%s)-start_epoch )); eta=0
        local done_units=$((overall_before*100+pct))
        ((done_units>0)) && eta=$((elapsed*(track_total*100-done_units)/done_units))
        frame_convert "$artist" "$album_no" "$album_total" "$track_no" "$track_total" "$track_name" "$pct" "$overall" "${bitrate:---}" "$size" "$duration" "$(human_duration "$elapsed")" "$(human_duration "$eta")"
        sleep 0.15
    done

    wait "$pid"; status=$?
    if ((status!=0)); then
        printf 'FILE: %s\n' "$src" >> "$error_log"
        cat "$error_tmp" >> "$error_log"
        printf '\n' >> "$error_log"
        rm -f "$dst"
    fi
    rm -f "$progress_tmp" "$error_tmp"
    return "$status"
}

run_artist() {
    local artist="$1" artist_dir="$2" out_dir="$DEST_ROOT/$artist"
    local -a tracks=() extras=()
    local -A album_seen=() album_index=()
    local total_tracks=0 total_albums=0 completed=0 failed=0 skipped=0 embedded=0 copied=0
    local source_bytes=0 dest_bytes=0 start_epoch elapsed_total reduced dst_pct
    local file rel album dst album_no duration_us has_image

    mkdir -p "$out_dir"
    while IFS= read -r -d '' file; do tracks+=("$file"); done < <(find "$artist_dir" -type f -iname '*.flac' -print0 | sort -z)
    total_tracks=${#tracks[@]}
    ((total_tracks>0)) || { clear_screen; printf 'Artist: %s\n\nNo FLAC tracks found.\n' "$artist"; return 0; }

    for file in "${tracks[@]}"; do
        rel="${file#"$artist_dir"/}"; album="${rel%/*}"; [[ "$album" == "$rel" ]] && album="Singles"
        if [[ -z "${album_seen[$album]+x}" ]]; then
            album_seen[$album]=1; total_albums=$((total_albums+1)); album_index[$album]=$total_albums
        fi
        source_bytes=$((source_bytes + $(file_size "$file")))
    done
    while IFS= read -r -d '' file; do
        extras+=("$file"); source_bytes=$((source_bytes + $(file_size "$file")))
    done < <(find "$artist_dir" -type f ! -iname '*.flac' -print0 | sort -z)

    LAST_ERROR_LOG="$out_dir/.flac2mp3-errors.log"
    : > "$LAST_ERROR_LOG"

    # Scan is a single stable frame; only current-file content changes.
    for file in "${tracks[@]}"; do
        frame_scan "$artist" "$total_tracks" "$total_albums" "$file"
        sleep 0.02
    done
    frame_scan "$artist" "$total_tracks" "$total_albums" "Complete"
    sleep 0.25

    start_epoch="$(date +%s)"
    for ((i=0;i<total_tracks;i++)); do
        file="${tracks[$i]}"
        rel="${file#"$artist_dir"/}"; album="${rel%/*}"; [[ "$album" == "$rel" ]] && album="Singles"
        album_no="${album_index[$album]}"
        dst="$out_dir/${rel%.*}.mp3"
        mkdir -p "${dst%/*}"

        if [[ -f "$dst" ]]; then
            skipped=$((skipped+1))
            continue
        fi

        duration_us="$(track_duration_us "$file")"
        if has_cover "$file"; then has_image=1; else has_image=0; fi
        if convert_track "$file" "$dst" "$duration_us" "$artist" "$album_no" "$total_albums" "$((i+1))" "$total_tracks" "$((completed+skipped))" "$start_epoch" "$LAST_ERROR_LOG"; then
            completed=$((completed+1)); embedded=$((embedded+has_image))
        else
            failed=$((failed+1))
        fi
    done

    for file in "${extras[@]}"; do
        rel="${file#"$artist_dir"/}"; dst="$out_dir/$rel"
        mkdir -p "${dst%/*}"
        [[ -e "$dst" ]] || { cp -p "$file" "$dst" && copied=$((copied+1)); }
    done

    dest_bytes=0
    while IFS= read -r -d '' file; do dest_bytes=$((dest_bytes + $(file_size "$file"))); done < <(find "$out_dir" -type f ! -name '.flac2mp3-errors.log' -print0)
    ((source_bytes>0)) && dst_pct=$((dest_bytes*100/source_bytes)) || dst_pct=0
    ((dst_pct>100)) && dst_pct=100
    reduced=$((source_bytes-dest_bytes)); ((reduced<0)) && reduced=0
    elapsed_total=$(( $(date +%s)-start_epoch ))

    frame_summary "$artist" "$(human_duration "$elapsed_total")" "$((completed+skipped))" "$total_tracks" "$failed" "$skipped" "$embedded" "$copied" "${#extras[@]}" "$(human_size "$source_bytes")" "$(human_size "$dest_bytes")" "$(human_size "$reduced")" "$dst_pct"
}

main() {
    hide_cursor
    while true; do
        frame_greeting
        IFS= read -r artist
        [[ -z "$artist" ]] && continue
        if ! artist_dir="$(find_artist_dir "$artist")"; then
            clear_screen
            printf 'FLAC → MP3 Converter\n\nArtist: %s\n\n%sArtist not found.%s\n\nPress Enter to continue.' "$artist" "$RED" "$RESET"
            read -r _
            continue
        fi
        run_artist "$artist" "$artist_dir"
        while true; do
            IFS= read -r -n 1 choice
            printf '\n'
            case "${choice^^}" in
                C) break ;;
                V) if [[ -s "$LAST_ERROR_LOG" ]]; then clear_screen; printf 'Error Log\n\n'; cat "$LAST_ERROR_LOG"; printf '\nPress Enter to return.'; read -r _; frame_summary "$artist" "$(human_duration 0)" 0 0 0 0 0 0 0 0B 0B 0B 0; else break; fi ;;
                Q|'') return 0 ;;
                *) ;;
            esac
        done
    done
}

main "$@"
