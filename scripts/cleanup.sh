#!/bin/bash
set -e

# Default values
LOG_RETENTION_HOURS=${LOG_RETENTION_HOURS:-168}  # 7 days
BACKUP_RETENTION_DAYS=${BACKUP_RETENTION_DAYS:-7}

# Cleanup old logs
cleanup_logs() {
    echo "Cleaning up old logs..."
    find $KAFKA_HOME/logs -name "*.log" -mtime +$LOG_RETENTION_HOURS -delete
    find $KAFKA_HOME/logs -name "*.gz" -mtime +$LOG_RETENTION_HOURS -delete
}

# Cleanup old backups
cleanup_backups() {
    echo "Cleaning up old backups..."
    find /var/lib/kafka/backup -name "*.tar.gz" -mtime +$BACKUP_RETENTION_DAYS -delete
    find /var/lib/kafka/backup -name "*.config" -mtime +$BACKUP_RETENTION_DAYS -delete
}

cleanup_logs
cleanup_backups 