#!/bin/bash

cd "$(dirname "$0")/.." || exit 1

while true; do

    # Obtener las ultimas 10 solicitudes de Nginx
    docker compose logs --no-log-prefix --no-color nginx 2>/dev/null \
        | grep 'status=[0-9][0-9][0-9]' \
        | tail -n 10 > monitoreo/ultimas_10.log

    # Calcular latencia y cache
    read -r promedio hits misses total < <(
        awk '
        {
            for (i = 1; i <= NF; i++) {
                split($i, dato, "=")

                if (dato[1] == "tiempo") {
                    suma += dato[2]
                    total++
                }

                if (dato[1] == "cache") {
                    if (dato[2] == "HIT") hits++
                    if (dato[2] == "MISS") misses++
                }
            }
        }
        END {
            if (total > 0)
                promedio = (suma / total) * 1000

            printf "%.2f %d %d %d\n", promedio, hits, misses, total
        }' monitoreo/ultimas_10.log
    )

    # Porcentaje de aciertos
    tasa=$(awk -v h="$hits" -v m="$misses" \
        'BEGIN {
            if (h+m > 0) printf "%.1f", h*100/(h+m)
            else print "0.0"
        }')

    # Conexiones de Nginx
    conexiones=$(curl -fsS --max-time 2 \
        http://localhost:8090/nginx_status \
        | awk '/Active connections:/ {print $3}')

    conexiones=${conexiones:-"Sin datos"}

    # Obtener CPU y memoria
    docker stats --no-stream \
        --format '{{.Name}}|{{.CPUPerc}}|{{.MemUsage}}' \
        $(docker compose ps -q) \
        > monitoreo/recursos.tmp 2>/dev/null

    # Mostrar datos en terminal
    clear
    echo "========================================"
    echo "      SPEEDRUNNERS - MONITOREO"
    echo "========================================"
    echo "Fecha: $(date '+%d/%m/%Y %H:%M:%S')"
    echo
    echo "Solicitudes analizadas: $total"
    echo "Latencia promedio: $promedio ms"
    echo "Cache HIT: $hits"
    echo "Cache MISS: $misses"
    echo "Tasa de aciertos: $tasa%"
    echo "Conexiones activas: $conexiones"
    echo
    echo "CPU Y MEMORIA"
    echo "----------------------------------------"

    filas=""

    while IFS='|' read -r nombre cpu memoria; do
        echo "$nombre | CPU: $cpu | RAM: $memoria"

        filas="$filas
        <tr>
            <td>$nombre</td>
            <td>$cpu</td>
            <td>$memoria</td>
        </tr>"
    done < monitoreo/recursos.tmp

    # Crear el reporte HTML
    cat > monitoreo/reporte.html <<EOF
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta http-equiv="refresh" content="5">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SpeedRunners - Monitoreo</title>

    <style>
        body {
            font-family: Arial, sans-serif;
            background: #f4f6fa;
            color: #202b3c;
            margin: 30px;
        }

        h1, p {
            text-align: center;
        }

        .contenedor {
            max-width: 950px;
            margin: auto;
        }

        .tarjetas {
            display: flex;
            flex-wrap: wrap;
            gap: 15px;
            margin: 30px 0;
        }

        .tarjeta {
            flex: 1;
            min-width: 170px;
            background: white;
            padding: 20px;
            border-radius: 10px;
            text-align: center;
            border: 1px solid #e1e5ec;
        }

        .numero {
            font-size: 26px;
            font-weight: bold;
            color: #2458b5;
        }

        table {
            width: 100%;
            border-collapse: collapse;
            background: white;
        }

        th, td {
            padding: 12px;
            border-bottom: 1px solid #ddd;
            text-align: left;
        }

        th {
            background: #1d304a;
            color: white;
        }
    </style>
</head>

<body>
    <div class="contenedor">
        <h1>SpeedRunners Inc.</h1>
        <p>Dashboard de monitoreo de servidores</p>
        <p>Actualizado: $(date '+%d/%m/%Y %H:%M:%S')</p>

        <div class="tarjetas">
            <div class="tarjeta">
                <h3>Latencia promedio</h3>
                <div class="numero">$promedio ms</div>
            </div>

            <div class="tarjeta">
                <h3>Cache HIT</h3>
                <div class="numero">$tasa%</div>
            </div>

            <div class="tarjeta">
                <h3>Solicitudes</h3>
                <div class="numero">$total</div>
            </div>

            <div class="tarjeta">
                <h3>Conexiones Nginx</h3>
                <div class="numero">$conexiones</div>
            </div>
        </div>

        <h2>Consumo de recursos</h2>

        <table>
            <tr>
                <th>Contenedor</th>
                <th>CPU</th>
                <th>Memoria</th>
            </tr>
            $filas
        </table>

        <p>Actualización automática cada 5 segundos</p>
    </div>
</body>
</html>
EOF

    sleep 5
done
