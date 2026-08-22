#!/usr/bin/env bash
set -u
set -o pipefail

LAST_ERROR_LOG=""
SOURCE_ROOT="${SOURCE_ROOT:-$HOME/storage/shared/Music/FLAC}"
DEST_ROOT="${DEST_ROOT:-$HOME/storage/shared/Music/MP3}"

YELLOW='\033[33m'
RED='\033[31m'
DIM='\033[2m'
RESET='\033[0m'

need_cmd() {
    command -v "$1" >/dev/null 2>&1 || {
        printf '%bMissing dependency: %s%b\n' "$RED" "$1" "$RESET" >&2
        exit 1
    }
}

need_cmd ffmpeg
need_cmd ffprobe
need_cmd find
need_cmd sort
need_cmd awk
need_cmd mktemp
need_cmd stat

human_size() {
    awk -v b="${1:-0}" 'BEGIN { split("B KiB MiB GiB TiB",u); i=1; while(b>=1024&&i<5){b/=1024;i++}; if(i==1)printf "%.0f %s",b,u[i]; else printf "%.1f %s",b,u[i] }'
}

human_duration() {
    awk -v s="${1:-0}" 'BEGIN { if(s<0)s=0; h=int(s/3600); m=int((s%3600)/60); x=int(s%60); if(h>0)printf "%02dh%02dm%02ds",h,m,x; else printf "%02dm%02ds",m,x }'
}

seconds_float() {
    awk -v s="${1:-0}" 'BEGIN { if(s=="N/A"||s=="")print 0; else printf "%.3f",s+0 }'
}

terminal_width() {
    local w
    w="$(tput cols 2>/dev/null || true)"
    [[ "$w" =~ ^[0-9]+$ ]] || w=80
    ((w<40)) && w=40
    printf '%s' "$w"
}

bar() {
    local pct="$1" width="$2" fill filled empty spaces
    ((pct<0)) && pct=0
    ((pct>100)) && pct=100
    fill=$((width-4)); ((fill<8)) && fill=8
    filled=$((fill*pct/100)); empty=$((fill-filled))
    printf -v spaces '%*s' "$empty" ''
    spaces=${spaces// /-}
    printf '%*s' "$filled" '' | tr ' ' '█'
    printf '%s%3d%%' "$spaces" "$pct"
}

find_artist_dir() {
    local wanted="$1" candidate base
    [[ -d "$SOURCE_ROOT/$wanted" ]] && { printf '%s\n' "$SOURCE_ROOT/$wanted"; return 0; }
    while IFS= read -r -d '' candidate; do
        base="${candidate##*/}"
        [[ "${base,,}" == "${wanted,,}" ]] && { printf '%s\n' "$candidate"; return 0; }
    done < <(find "$SOURCE_ROOT" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null)
    return 1
}

track_duration_us() {
    local file="$1" d
    d="$(ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "$file" 2>/dev/null || true)"
    awk -v s="${d:-0}" 'BEGIN{printf "%.0f",(s+0)*1000000}'
}

track_duration_seconds() {
    local file="$1" d
    d="$(ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "$file" 2>/dev/null || true)"
    seconds_float "$d"
}

has_attached_picture() {
    local file="$1"
    [[ "$(ffprobe -v error -select_streams v -show_entries stream=disposition.attached_pic -of default=nw=1:nk=1 "$file" 2>/dev/null)" == "1" ]]
}

convert_track() {
    local src="$1" dst="$2" duration_us="$3" total_tracks="$4" completed="$5" start_epoch="$6" error_log="$7"
    local current_pct=0 overall_pct=0 elapsed=0 eta=0 bitrate="" size="" duration_label track_name
    local width ff_status ff_pid progress_tmp error_tmp out_time_us done_units
    width="$(terminal_width)"
    track_name="${src##*/}"
    duration_label="$(human_duration "$(track_duration_seconds "$src")")"
    progress_tmp="$(mktemp)"
    error_tmp="$(mktemp)"

    mkdir -p "${dst%/*}"
    ffmpeg -hide_banner -loglevel error -nostats \
        -i "$src" -map 0:a:0 -map 0:v? -map_metadata 0 \
        -c:a libmp3lame -q:a 2 -c:v mjpeg \
        -id3v2_version 3 -write_id3v1 1 \
        -progress "$progress_tmp" -nostdin -y "$dst" 2>"$error_tmp" &
    ff_pid=$!

    while kill -0 "$ff_pid" 2>/dev/null; do
        if [[ -s "$progress_tmp" ]]; then
            out_time_us="$(awk -F= '$1=="out_time_us"{v=$2}END{print v+0}' "$progress_tmp")"
            bitrate="$(awk -F= '$1=="bitrate"{v=$2}END{print v}' "$progress_tmp")"
            if ((duration_us>0)); then current_pct=$((out_time_us*100/duration_us)); else current_pct=0; fi
            ((current_pct>100)) && current_pct=100
            overall_pct=$(( (completed*100+current_pct)/total_tracks ))
            size="$(stat -c '%s' "$dst" 2>/dev/null || stat -f '%z' "$dst" 2>/dev/null || printf '0')"
            size="$(human_size "$size")"
            elapsed=$(( $(date +%s)-start_epoch ))
            done_units=$((completed*100+current_pct)); eta=0
            ((done_units>0)) && eta=$((elapsed*(total_tracks*100-done_units)/done_units))
            printf '\033[11A%s\n%s\nEncoding...\nBitrate:         %-10s\nSize:            %-10s\nTrack Duration:  %-10s\nElapsed:         %-10s\nETA:             %-10s\n%s\n\n%d%% Complete\n' \
                "$track_name" "$(bar "$current_pct" "$width")" "${bitrate:---}" "${size:---}" "$duration_label" "$(human_duration "$elapsed")" "$(human_duration "$eta")" "$(bar "$overall_pct" "$width")" "$overall_pct"
        fi
        sleep 0.15
    done

    wait "$ff_pid"; ff_status=$?
    if ((ff_status==0)); then
        bitrate="$(awk -F= '$1=="bitrate"{v=$2}END{print v}' "$progress_tmp")"
        overall_pct=$(( (completed+1)*100/total_tracks ))
        size="$(stat -c '%s' "$dst" 2>/dev/null || stat -f '%z' "$dst" 2>/dev/null || printf '0')"
        size="$(human_size "$size")"
        elapsed=$(( $(date +%s)-start_epoch ))
        printf '\033[11A%s\n%s\nEncoding...\nBitrate:         %-10s\nSize:            %-10s\nTrack Duration:  %-10s\nElapsed:         %-10s\nETA:             00m00s\n%s\n\n%d%% Complete\n' \
            "$track_name" "$(bar 100 "$width")" "${bitrate:---}" "${size:---}" "$duration_label" "$(human_duration "$elapsed")" "$(bar "$overall_pct" "$width")" "$overall_pct"
    else
        { printf 'FILE: %s\n' "$src"; cat "$error_tmp"; printf '\n'; } >> "$error_log"
        rm -f "$dst"
    fi
    rm -f "$progress_tmp" "$error_tmp"
    return "$ff_status"
}

run_artist() {
    local artist="$1" artist_dir="$2" out_dir="$DEST_ROOT/$artist"
    local error_log="$out_dir/.flac2mp3-errors.log"
    local -a tracks=() extras=()
    local -A album_index=() seen_album=()
    local total_tracks=0 total_albums=0 completed=0 failed=0 skipped=0 embedded=0 copied=0 conversion_started=0
    local source_bytes=0 dest_bytes=0 start_epoch
    local file rel dst album album_no duration duration_us finished=0 has_cover

    mkdir -p "$out_dir"
    while IFS= read -r -d '' file; do tracks+=("$file"); done < <(find "$artist_dir" -type f -iname '*.flac' -print0 | sort -z)
    total_tracks=${#tracks[@]}
    ((total_tracks>0)) || { printf '%bNo FLAC tracks found.%b\n' "$YELLOW" "$RESET"; return 0; }

    for file in "${tracks[@]}"; do
        rel="${file#"$artist_dir"/}"; album="${rel%/*}"; [[ "$album" == "$rel" ]] && album="Singles"
        if [[ -z "${seen_album[$album]+x}" ]]; then seen_album[$album]=1; total_albums=$((total_albums+1)); album_index[$album]=$total_albums; fi
        source_bytes=$((source_bytes + $(stat -c '%s' "$file" 2>/dev/null || stat -f '%z' "$file" 2>/dev/null || printf '0')))
    done
    while IFS= read -r -d '' file; do
        extras+=("$file")
        source_bytes=$((source_bytes + $(stat -c '%s' "$file" 2>/dev/null || stat -f '%z' "$file" 2>/dev/null || printf '0')))
    done < <(find "$artist_dir" -type f ! -iname '*.flac' -print0 | sort -z)
    : > "$error_log"; LAST_ERROR_LOG="$error_log"

    printf '\033[1A\033[KArtist: %s\n\nScanning...\n' "$artist"
    for file in "${tracks[@]}"; do printf '\r\033[K%s' "${file##*/}"; sleep 0.01; done
    printf '\n\nFound: %d tracks\n       %d albums\n\n' "$total_tracks" "$total_albums"

    start_epoch="$(date +%s)"
    for ((i=0;i<total_tracks;i++)); do
        file="${tracks[$i]}"; rel="${file#"$artist_dir"/}"; album="${rel%/*}"; [[ "$album" == "$rel" ]] && album="Singles"
        album_no="${album_index[$album]}"; duration="$(track_duration_seconds "$file")"; duration_us="$(track_duration_us "$file")"; dst="$out_dir/${rel%.*}.mp3"
        mkdir -p "${dst%/*}"
        if [[ -f "$dst" ]]; then skipped=$((skipped+1)); continue; fi

        printf '\033[2K\rArtist: %s > Album %d/%d > Track %d/%d >\n%s\n%s\nEncoding...\nBitrate:         --\nSize:            --\nTrack Duration:  %s\nElapsed:         00m00s\nETA:             --\n%s\n\n0%% Complete\n' \
            "$artist" "$album_no" "$total_albums" "$((i+1))" "$total_tracks" "${file##*/}" "$(bar 0 "$(terminal_width)")" "$(human_duration "$duration")" "$(bar "$(( (completed+skipped)*100/total_tracks ))" "$(terminal_width)")"
        has_cover=0; has_attached_picture "$file" && has_cover=1
        conversion_started=1; finished=$((completed+skipped))
        if convert_track "$file" "$dst" "$duration_us" "$total_tracks" "$finished" "$start_epoch" "$error_log"; then
            completed=$((completed+1)); ((has_cover)) && embedded=$((embedded+1))
        else failed=$((failed+1)); fi
    done

    for file in "${extras[@]}"; do
        rel="${file#"$artist_dir"/}"; dst="$out_dir/$rel"; mkdir -p "${dst%/*}"
        [[ -e "$dst" ]] && continue
        cp -p "$file" "$dst" && copied=$((copied+1))
    done

    dest_bytes=0
    while IFS= read -r -d '' file; do dest_bytes=$((dest_bytes + $(stat -c '%s' "$file" 2>/dev/null || stat -f '%z' "$file" 2>/dev/null || printf '0'))); done < <(find "$out_dir" -type f ! -name '.flac2mp3-errors.log' -print0)
    local elapsed_total=$(( $(date +%s)-start_epoch )) reduced=$((source_bytes-dest_bytes)) dest_pct=0
    ((reduced<0)) && reduced=0; ((source_bytes>0)) && dest_pct=$((dest_bytes*100/source_bytes)); finished=$((completed+skipped))
    ((conversion_started)) && printf '\033[12A'
    printf 'Artist: %s\n\n%s elapsed\n> 100%% [%d/%d]\n> [%d] failed ; [%d] skipped\n> [%d/%d] images embedded\n> [%d/%d] extra files copied\n\n[%s] Source FLACs + extras\n%s\n\n[%s] Converted MP3s + extras\n%s\n\n> %s reduced\n\n──────────────────────────────────────────\n\n[C] Convert another artist\n[Q] Quit\n' \
        "$artist" "$(human_duration "$elapsed_total")" "$finished" "$total_tracks" "$failed" "$skipped" "$embedded" "$total_tracks" "$copied" "${#extras[@]}" "$(human_size "$source_bytes")" "$(bar 100 52)" "$(human_size "$dest_bytes")" "$(bar "$dest_pct" 52)" "$(human_size "$reduced")"
    ((failed>0)) && printf '[V] View error log\n'
}

main() {
    while true; do
        printf 'Source      : %s\nDestination : %s\n\nArtist: ' "$SOURCE_ROOT" "$DEST_ROOT"
        IFS= read -r artist; [[ -z "$artist" ]] && continue
        if ! artist_dir="$(find_artist_dir "$artist")"; then printf '%bArtist not found: %s%b\n\n' "$RED" "$artist" "$RESET"; continue; fi
        run_artist "$artist" "$artist_dir"; printf '\n'; IFS= read -r -n 1 choice; printf '\n'
        case "${choice^^}" in
            C) printf '\n'; continue ;;
            V) [[ -s "$LAST_ERROR_LOG" ]] && cat "$LAST_ERROR_LOG" || printf '%bNo error log entries.%b\n' "$DIM" "$RESET"; continue ;;
            Q|'') exit 0 ;;
            *) exit 0 ;;
        esac
    done
}

main "$@"
