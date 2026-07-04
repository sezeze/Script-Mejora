#!/usr/bin/env bash

# ==============================================================================
# SCRIPT DE MITIGACIÓN TOTAL - COMPLETO PARA PRODUCCIÓN
# Curso: Sistemas Operativos de Código Abierto
# ==============================================================================

set -euo pipefail

PUERTO_HTTP=80
PUERTO_HTTPS=443
CADENA_ATAQUE="db.sql"
LIMITE_SYN="10/s"
BURST_SYN=20

echo "============================================================="
echo "[*] INICIANDO DESPLIEGUE DEL ESCUDO COMPLETO DE PRODUCCIÓN"
echo "============================================================="

# ------------------------------------------------------------------------------
# BLOQUE 1: Verificación de Privilegios
# ------------------------------------------------------------------------------
if [ "$EUID" -ne 0 ]; then
    echo "[-] ERROR: Este script debe ser ejecutado como ROOT" >&2
    exit 1
fi

# ------------------------------------------------------------------------------
# BLOQUE 2: Idempotencia y Limpieza
# ------------------------------------------------------------------------------
echo "[+] Limpiando y asegurando cadena 'DEFENSA'..."
iptables -F DEFENSA 2>/dev/null || iptables -N DEFENSA
iptables -C INPUT -j DEFENSA 2>/dev/null || iptables -A INPUT -j DEFENSA

# ------------------------------------------------------------------------------
# BLOQUE 3: Regla de Oro (Conexiones Existentes)
# ------------------------------------------------------------------------------
echo "[+] Permitiendo tráfico legítimo fluido (ESTABLISHED,RELATED)..."
iptables -A DEFENSA -m state --state ESTABLISHED,RELATED -j ACCEPT

# ------------------------------------------------------------------------------
# BLOQUE 4: Capa 7 (DPI por firma) + [NUEVO: Registro de LOGS]
# ------------------------------------------------------------------------------
echo "[+] Configurando Defensa Capa 7 y auditoría para '$CADENA_ATAQUE'..."
# Primero registramos el intento de ataque en el log del Kernel antes de tirarlo
iptables -A DEFENSA -p tcp --dport "$PUERTO_HTTP" -m string --string "$CADENA_ATAQUE" --algo bm -m limit --limit 3/min -j LOG --log-prefix "IPTABLES-CAPA7-DROP: "

# Luego destruimos el paquete
iptables -A DEFENSA -p tcp --dport "$PUERTO_HTTP" -m string --string "$CADENA_ATAQUE" --algo bm -j DROP

# ------------------------------------------------------------------------------
# BLOQUE 5: Capa 4 (Rate Limiting) + [NUEVO: Registro de LOGS en excesos]
# ------------------------------------------------------------------------------
echo "[+] Configurando Rate Limiting SYN y auditoría de inundación..."

# Permite tráfico limpio bajo el umbral
iptables -A DEFENSA -p tcp --syn --dport "$PUERTO_HTTP" -m limit --limit "$LIMITE_SYN" --limit-burst "$BURST_SYN" -j ACCEPT
iptables -A DEFENSA -p tcp --syn --dport "$PUERTO_HTTPS" -m limit --limit "$LIMITE_SYN" --limit-burst "$BURST_SYN" -j ACCEPT

# [NUEVO] Registra en el log del sistema si alguien superó el límite (máximo 3 alertas por minuto para no saturar)
iptables -A DEFENSA -p tcp --syn -m limit --limit 3/min -j LOG --log-prefix "IPTABLES-SYN-FLOOD: "

# Descarta los paquetes atacantes que superaron el límite
iptables -A DEFENSA -p tcp --syn --dport "$PUERTO_HTTP" -j DROP
iptables -A DEFENSA -p tcp --syn --dport "$PUERTO_HTTPS" -j DROP

# ------------------------------------------------------------------------------
# [NUEVO] BLOQUE 6: Persistencia (Guardado automático)
# ------------------------------------------------------------------------------
echo "[+] Guardando reglas de forma persistente en el sistema..."
if command -v iptables-save &> /dev/null; then
    # Guarda una copia en la ruta estándar de Linux
    iptables-save > /etc/iptables/rules.v4 2>/dev/null || echo "[!] Nota: Instale 'iptables-persistent' para activar la carga automática al reiniciar."
fi

echo "============================================================="
echo "[+] ESCUDO TOTALMENTE DESPLEGADO, AUDITADO Y ASEGURADO"
echo "============================================================="


