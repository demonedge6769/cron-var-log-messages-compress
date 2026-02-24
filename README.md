# cron-var-log-messages-compress
Automate /var/log/messages compress with cronjob

How to use the file.

1. download the script
2. chmod +x logcompresser.sh
3. crontab -e
4. */30 * * * * {file path}[eg. /root/logcompresser.sh]

It will check every 30m and compress the file if exceed 400mb

