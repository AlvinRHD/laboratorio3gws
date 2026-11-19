#!/bin/bash

# Laboratorio SpeedRunners
# Pruebas de estres con Apache Benchmark

cd "$(dirname "$0")/.." || exit 1

echo "=================================="
echo " SPEEDRUNNERS - PRUEBA DE ESTRES"
echo "=================================="

echo
echo "Solicitudes: 1000"
echo "Usuarios concurrentes simulados: 100"
echo

# Verificar que Nginx responda
if ! curl -fsS -o /dev/null http://127.0.0.1:8090/; then
    echo "Error: Nginx no responde"
    exit 1
fi

# Prueba 1: con cache
echo "PRUEBA 1: CON CACHE"

ab -n 1000 -c 100 -s 30 \
    http://127.0.0.1:8090/ \
    > pruebas/estres_cache.txt

echo "Resultados guardados"

echo

# Prueba 2: sin cache
echo "PRUEBA 2: SIN CACHE"

ab -n 1000 -c 100 -s 30 \
    "http://127.0.0.1:8090/?nocache=1" \
    > pruebas/estres_sin_cache.txt

echo "Resultados guardados"

echo

# Resumen de ambas pruebas
{
    for archivo in pruebas/estres_cache.txt pruebas/estres_sin_cache.txt
    do
        echo "=================================="
        echo "$archivo"
        echo "=================================="

        grep -E \
        '^(Concurrency Level|Complete requests|Failed requests|Non-2xx responses|Requests per second|Time per request|Time taken for tests):' \
        "$archivo"

        echo
    done
} | tee pruebas/resumen_estres.txt

echo "Pruebas finalizadas."
