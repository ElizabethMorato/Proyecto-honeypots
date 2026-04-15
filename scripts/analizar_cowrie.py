import json
with open("C:/Proyecto-honeypots/logs/cowrie.json", "r", encoding="utf-8") as archivo:

    for linea in archivo:
        linea = linea.strip()
        if not linea:
            continue
        try:
            evento = json.loads(linea)
            eventid = evento.get("eventid")
            
            if eventid == "cowrie.login.success":
                print("LOGIN EXITOSO")
                print("  IP:       ", evento.get("src_ip"))
                print("  Usuario:  ", evento.get("username"))
                print("  Password: ", evento.get("password"))
                print("  Sesion:   ", evento.get("session"))
                print("  Fecha:    ", evento.get("timestamp"))
                print("-" * 40)
                
            elif eventid == "cowrie.command.input":
                print("COMANDO EJECUTADO")
                print("  IP:      ", evento.get("src_ip"))
                print("  Comando: ", evento.get("input"))
                print("  Sesion:  ", evento.get("session"))
                print("-" * 40)
                
            elif eventid == "cowrie.session.file_download":
                print("DESCARGA DE ARCHIVO")
                print("  IP:    ", evento.get("src_ip"))
                print("  URL:   ", evento.get("url"))
                print("  Hash:  ", evento.get("shasum"))
                print("-" * 40)
                
            elif eventid == "cowrie.session.closed":
                print("SESION CERRADA")
                print("  Duracion: ", evento.get("duration"), "segundos")
                print("=" * 40)
                
        except json.JSONDecodeError:
            continue