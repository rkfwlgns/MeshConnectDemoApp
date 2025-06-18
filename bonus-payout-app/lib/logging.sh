#!/opt/homebrew/bin/bash

# Logging functions for Bonus Payout Application
# Handles application logs, payout tracking, and error reporting

LOG_DIR="$SCRIPT_DIR/logs"
APP_LOG="$LOG_DIR/app.log"
PAYOUT_LOG="$LOG_DIR/payouts.log"
ERROR_LOG="$LOG_DIR/errors.log"

# Initialize logging
init_logging() {
    mkdir -p "$LOG_DIR"
    
    # Create log files if they don't exist
    touch "$APP_LOG" "$PAYOUT_LOG" "$ERROR_LOG"
    
    # Set proper permissions
    chmod 640 "$APP_LOG" "$PAYOUT_LOG" "$ERROR_LOG"
    
    log_info "Logging system initialized"
}

# Get timestamp for logs
get_timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# Generic log function
write_log() {
    local level="$1"
    local message="$2"
    local logfile="$3"
    local timestamp=$(get_timestamp)
    
    echo "[$timestamp] [$level] $message" >> "$logfile"
}

# Info level logging
log_info() {
    local message="$1"
    write_log "INFO" "$message" "$APP_LOG"
}

# Warning level logging
log_warning() {
    local message="$1"
    write_log "WARNING" "$message" "$APP_LOG"
}

# Error level logging
log_error() {
    local message="$1"
    write_log "ERROR" "$message" "$ERROR_LOG"
    write_log "ERROR" "$message" "$APP_LOG"
}

# Debug level logging (only if DEBUG is enabled)
log_debug() {
    local message="$1"
    if [[ "${DEBUG:-false}" == "true" ]]; then
        write_log "DEBUG" "$message" "$APP_LOG"
    fi
}

# Log payout transactions
log_payout() {
    local recipient_email="$1"
    local recipient_address="$2"
    local amount="$3"
    local symbol="$4"
    local network="$5"
    local description="$6"
    local link_token="$7"
    local status="$8"
    local timestamp=$(get_timestamp)
    
    local log_entry="[$timestamp] PAYOUT | Email: $recipient_email | Address: $recipient_address | Amount: $amount $symbol | Network: $network | Status: $status | Description: $description | LinkToken: ${link_token:0:20}..."
    
    echo "$log_entry" >> "$PAYOUT_LOG"
    log_info "Payout logged: $recipient_email - $amount $symbol ($status)"
}

# Log API requests
log_api_request() {
    local method="$1"
    local endpoint="$2"
    local status_code="$3"
    local response_time="$4"
    
    local message="API Request: $method $endpoint | Status: $status_code | Time: ${response_time}ms"
    log_info "$message"
}

# Log configuration changes
log_config_change() {
    local setting="$1"
    local old_value="$2"
    local new_value="$3"
    
    local message="Configuration changed: $setting | Old: ${old_value:-'<empty>'} | New: ${new_value:-'<empty>'}"
    log_info "$message"
}

# Log security events
log_security() {
    local event="$1"
    local details="$2"
    
    local message="SECURITY: $event | Details: $details"
    write_log "SECURITY" "$message" "$ERROR_LOG"
    write_log "SECURITY" "$message" "$APP_LOG"
}

# Display recent logs
show_recent_logs() {
    local log_type="$1"
    local lines="${2:-20}"
    
    case "$log_type" in
        "app"|"application")
            echo -e "${BLUE}Recent Application Logs (last $lines lines):${NC}"
            echo "=========================================="
            if [[ -f "$APP_LOG" ]]; then
                tail -n "$lines" "$APP_LOG"
            else
                echo "No application logs found."
            fi
            ;;
        "payout"|"payouts")
            echo -e "${BLUE}Recent Payout Logs (last $lines lines):${NC}"
            echo "======================================"
            if [[ -f "$PAYOUT_LOG" ]]; then
                tail -n "$lines" "$PAYOUT_LOG"
            else
                echo "No payout logs found."
            fi
            ;;
        "error"|"errors")
            echo -e "${BLUE}Recent Error Logs (last $lines lines):${NC}"
            echo "====================================="
            if [[ -f "$ERROR_LOG" ]]; then
                tail -n "$lines" "$ERROR_LOG"
            else
                echo "No error logs found."
            fi
            ;;
        *)
            echo -e "${RED}Invalid log type. Use: app, payout, or error${NC}"
            return 1
            ;;
    esac
}

# Search logs
search_logs() {
    local search_term="$1"
    local log_type="$2"
    
    if [[ -z "$search_term" ]]; then
        echo -e "${RED}Please provide a search term.${NC}"
        return 1
    fi
    
    case "$log_type" in
        "app"|"application")
            echo -e "${BLUE}Searching application logs for: '$search_term'${NC}"
            grep -i "$search_term" "$APP_LOG" 2>/dev/null || echo "No matches found."
            ;;
        "payout"|"payouts")
            echo -e "${BLUE}Searching payout logs for: '$search_term'${NC}"
            grep -i "$search_term" "$PAYOUT_LOG" 2>/dev/null || echo "No matches found."
            ;;
        "error"|"errors")
            echo -e "${BLUE}Searching error logs for: '$search_term'${NC}"
            grep -i "$search_term" "$ERROR_LOG" 2>/dev/null || echo "No matches found."
            ;;
        "all")
            echo -e "${BLUE}Searching all logs for: '$search_term'${NC}"
            echo "--- Application Logs ---"
            grep -i "$search_term" "$APP_LOG" 2>/dev/null || echo "No matches in application logs."
            echo "--- Payout Logs ---"
            grep -i "$search_term" "$PAYOUT_LOG" 2>/dev/null || echo "No matches in payout logs."
            echo "--- Error Logs ---"
            grep -i "$search_term" "$ERROR_LOG" 2>/dev/null || echo "No matches in error logs."
            ;;
        *)
            echo -e "${RED}Invalid log type. Use: app, payout, error, or all${NC}"
            return 1
            ;;
    esac
}

# Archive old logs
archive_logs() {
    local days_to_keep="${1:-30}"
    local archive_dir="$LOG_DIR/archive"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    
    mkdir -p "$archive_dir"
    
    echo "Archiving logs older than $days_to_keep days..."
    
    # Archive logs
    for logfile in "$APP_LOG" "$PAYOUT_LOG" "$ERROR_LOG"; do
        if [[ -f "$logfile" ]]; then
            local basename=$(basename "$logfile")
            local archive_file="$archive_dir/${basename}_${timestamp}"
            
            # Copy current log to archive
            cp "$logfile" "$archive_file"
            
            # Keep only recent entries in current log
            tail -n 1000 "$logfile" > "${logfile}.tmp"
            mv "${logfile}.tmp" "$logfile"
            
            echo "Archived: $basename -> ${archive_file}"
        fi
    done
    
    # Remove old archive files
    find "$archive_dir" -type f -mtime +$days_to_keep -delete 2>/dev/null
    
    log_info "Log archival completed. Kept last $days_to_keep days of logs."
}

# Get log statistics
get_log_stats() {
    echo -e "${BLUE}Log Statistics:${NC}"
    echo "==============="
    
    if [[ -f "$APP_LOG" ]]; then
        local app_lines=$(wc -l < "$APP_LOG")
        local app_size=$(du -h "$APP_LOG" | cut -f1)
        echo "Application Log: $app_lines lines, $app_size"
    fi
    
    if [[ -f "$PAYOUT_LOG" ]]; then
        local payout_lines=$(wc -l < "$PAYOUT_LOG")
        local payout_size=$(du -h "$PAYOUT_LOG" | cut -f1)
        local total_payouts=$(grep -c "PAYOUT" "$PAYOUT_LOG" 2>/dev/null || echo "0")
        echo "Payout Log: $payout_lines lines, $payout_size, $total_payouts payouts"
    fi
    
    if [[ -f "$ERROR_LOG" ]]; then
        local error_lines=$(wc -l < "$ERROR_LOG")
        local error_size=$(du -h "$ERROR_LOG" | cut -f1)
        local total_errors=$(grep -c "ERROR" "$ERROR_LOG" 2>/dev/null || echo "0")
        echo "Error Log: $error_lines lines, $error_size, $total_errors errors"
    fi
    
    echo ""
    echo "Log Directory: $LOG_DIR"
    echo "Total Log Size: $(du -sh "$LOG_DIR" | cut -f1)"
}

# Export logs for analysis
export_logs() {
    local export_format="${1:-txt}"
    local export_file="$SCRIPT_DIR/logs_export_$(date +%Y%m%d_%H%M%S)"
    
    case "$export_format" in
        "txt")
            export_file="${export_file}.txt"
            {
                echo "Bonus Payout Application - Log Export"
                echo "Generated: $(date)"
                echo "======================================="
                echo ""
                echo "APPLICATION LOGS:"
                echo "-----------------"
                cat "$APP_LOG" 2>/dev/null || echo "No application logs."
                echo ""
                echo "PAYOUT LOGS:"
                echo "------------"
                cat "$PAYOUT_LOG" 2>/dev/null || echo "No payout logs."
                echo ""
                echo "ERROR LOGS:"
                echo "-----------"
                cat "$ERROR_LOG" 2>/dev/null || echo "No error logs."
            } > "$export_file"
            ;;
        "csv")
            export_file="${export_file}.csv"
            {
                echo "Timestamp,Level,Message,LogType"
                # Process application logs
                awk -F'[][]' '/^\[.*\] \[.*\]/ {
                    timestamp = $2; level = $4; message = $0;
                    gsub(/^\[.*\] \[.*\] /, "", message);
                    gsub(/"/, "\"\"", message);
                    print timestamp "," level ",\"" message "\",APP"
                }' "$APP_LOG" 2>/dev/null
                # Process payout logs
                awk -F'[][]' '/^\[.*\] PAYOUT/ {
                    timestamp = $2; level = "PAYOUT"; message = $0;
                    gsub(/^\[.*\] /, "", message);
                    gsub(/"/, "\"\"", message);
                    print timestamp "," level ",\"" message "\",PAYOUT"
                }' "$PAYOUT_LOG" 2>/dev/null
                # Process error logs
                awk -F'[][]' '/^\[.*\] \[.*\]/ {
                    timestamp = $2; level = $4; message = $0;
                    gsub(/^\[.*\] \[.*\] /, "", message);
                    gsub(/"/, "\"\"", message);
                    print timestamp "," level ",\"" message "\",ERROR"
                }' "$ERROR_LOG" 2>/dev/null
            } > "$export_file"
            ;;
        *)
            echo -e "${RED}Invalid export format. Use: txt or csv${NC}"
            return 1
            ;;
    esac
    
    echo -e "${GREEN}Logs exported to: $export_file${NC}"
    log_info "Logs exported to $export_file in $export_format format"
}
