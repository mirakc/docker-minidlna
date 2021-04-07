PIDFILE=/var/run/minidlna/minidlna.pid
INTERVAL=${MINIDLNA_REBUILD_INTERVAL:-300}

# Remove old pid file if it exists.
[ -f $PIDFILE ] && rm -f $PIDFILE

# Start a minidlnad daemon.
/usr/local/sbin/minidlnad -d -f /etc/minidlna.conf -P $PIDFILE &

# Rebuild the index periodically.
while true;
do
    /usr/local/sbin/minidlnad -f /etc/minidlna.conf -P $PIDFILE -U
    sleep $INTERVAL
done
