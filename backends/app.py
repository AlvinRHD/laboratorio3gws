import json
import os
import time

from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

nombre = os.getenv("BACKEND_NAME", "backend")
delay = int(os.getenv("DELAY_MS", "500"))


class Servidor(BaseHTTPRequestHandler):

    def do_GET(self):
        # Simulamos un servidor lento
        time.sleep(delay / 1000)

        datos = {
            "aplicacion": "SpeedRunners Inc.",
            "servidor": nombre,
            "delay_ms": delay,
            "contenido": "Pedido procesado correctamente. " * 200
        }

        respuesta = json.dumps(datos).encode("utf-8")

        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(respuesta)))
        self.send_header("X-Backend", nombre)
        self.end_headers()

        self.wfile.write(respuesta)


servidor = ThreadingHTTPServer(("0.0.0.0", 8000), Servidor)

print(f"Iniciando {nombre} con delay de {delay}ms", flush=True)

servidor.serve_forever()
