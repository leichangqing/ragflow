pkill npm
pkill -f "docker/entrypoint.sh"
ps aux | grep ragflow | grep -v grep | awk '{print $2}' | xargs kill
