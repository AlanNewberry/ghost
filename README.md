# Ghost - Herramienta de Modo Monitor WiFi para Linux

**ghost.sh** — Script Bash para activar el modo monitor en interfaces WiFi de forma rápida, segura y automatizada.

**Versión:** 2.0.0

---

## Descripción

Desarrollé **ghost** porque necesitaba una herramienta confiable para poner adaptadores WiFi en modo monitor sin tener que recordar todos los pasos manuales cada vez. Me cansé de escribir los mismos comandos una y otra vez, así que automaticé todo el proceso en un solo script.

Ghost detecta automáticamente tus interfaces inalámbricas, mata los procesos que interfieren, activa el modo monitor en el canal que vos elijas y te deja todo listo para trabajar. Cuando terminás, restaura la interfaz al modo managed con un simple Ctrl+C.

Lo pensé para que sea simple de usar, pero robusto por dentro. Maneja errores, valida entradas y te muestra información útil sobre el chipset y driver de tu adaptador.

---

## Características

- **Detección automática de interfaces WiFi** mediante `iw dev` e `iwconfig`
- **Activación de modo monitor** en cualquier interfaz inalámbrica compatible
- **Selección de canal** con validación completa (canales 1 a 196, incluyendo 2.4 GHz, 5 GHz y 6 GHz)
- **Información de chipset y driver** del adaptador WiFi detectado
- **Eliminación de procesos conflictivos** vía `airmon-ng check kill`
- **Restauración automática** de la interfaz al modo managed con Ctrl+C (signal trap)
- **Impresión de comandos de restauración** para que puedas ejecutarlos manualmente si lo necesitás
- **Listado de interfaces** disponibles con la flag `-l`
- **Soporte de flags CLI** para uso no interactivo y scripting
- **Compatible con Kali Linux, Parrot OS, Ubuntu, Debian** y cualquier distribución basada en Linux

---

## Requisitos

| Requisito | Detalle |
|-----------|---------|
| Sistema operativo | Linux (kernel con soporte para modo monitor) |
| Shell | Bash 4.0 o superior |
| Privilegios | root o sudo |
| `iw` | Herramienta de configuración WiFi |
| `iwconfig` | Parte del paquete `wireless-tools` |
| `airmon-ng` | Parte de la suite `aircrack-ng` |
| `ip` | Herramienta de red del paquete `iproute2` |

### Instalar dependencias en Debian/Ubuntu/Kali

```bash
sudo apt update
sudo apt install iw wireless-tools aircrack-ng iproute2
```

---

## Instalación

```bash
git clone https://github.com/44ghost44/ghost.git
cd ghost
chmod +x ghost.sh
```

Para tenerlo disponible desde cualquier lugar:

```bash
sudo cp ghost.sh /usr/local/bin/ghost
```

---

## Uso

### Modo interactivo (detección automática)

```bash
sudo ./ghost.sh
```

El script detecta la interfaz WiFi automáticamente, muestra la información del chipset y driver, mata los procesos conflictivos y activa el modo monitor.

### Especificar interfaz

```bash
sudo ./ghost.sh -i wlan0
```

### Especificar interfaz y canal

```bash
sudo ./ghost.sh -i wlan0 -c 6
```

### Modo monitor en canal 5 GHz

```bash
sudo ./ghost.sh -i wlan0 -c 36
```

### Listar interfaces WiFi disponibles

```bash
sudo ./ghost.sh -l
```

### Ver la versión

```bash
./ghost.sh -v
```

### Ver la ayuda

```bash
./ghost.sh -h
```

---

## Opciones CLI

| Flag | Argumento | Descripción |
|------|-----------|-------------|
| `-i` | `IFACE` | Especifica la interfaz WiFi a usar (ej: `wlan0`, `wlan1`) |
| `-c` | `CHANNEL` | Establece el canal para el modo monitor (1-196) |
| `-l` | — | Lista todas las interfaces inalámbricas detectadas |
| `-h` | — | Muestra la ayuda con todas las opciones disponibles |
| `-v` | — | Muestra la versión del script |

---

## Restaurar la interfaz

Cuando presionás **Ctrl+C**, ghost restaura automáticamente la interfaz al modo managed. Si por alguna razón la restauración automática no funciona, el script imprime los comandos necesarios para que los ejecutes vos mismo:

```bash
sudo airmon-ng stop wlan0mon
sudo ip link set wlan0 down
sudo iw dev wlan0 set type managed
sudo ip link set wlan0 up
sudo systemctl restart NetworkManager
```

---

## Compatibilidad de adaptadores

Ghost funciona con cualquier adaptador WiFi cuyo chipset y driver soporten modo monitor en Linux. Probé el script con varios adaptadores y acá te dejo una lista de chipsets populares compatibles:

| Chipset | Driver | Adaptadores comunes |
|---------|--------|---------------------|
| Atheros AR9271 | `ath9k_htc` | Alfa AWUS036NHA, TP-Link TL-WN722N v1 |
| Ralink RT3070 | `rt2800usb` | Alfa AWUS036NH |
| Ralink RT5370 | `rt2800usb` | Varios adaptadores USB económicos |
| Realtek RTL8812AU | `88XXau` / `rtl8812au` | Alfa AWUS036ACH, Alfa AWUS036ACM |
| Realtek RTL8814AU | `8814au` | Alfa AWUS1900 |
| Intel AX200/AX210 | `iwlwifi` | Adaptadores internos (soporte limitado) |
| MediaTek MT7612U | `mt76x2u` | Alfa AWUS036ACM, Netgear A6210 |

Si tu adaptador no aparece en la lista, probalo igualmente. Ghost detecta la interfaz si el kernel la reconoce.

---

## Aviso legal

Creé esta herramienta con fines educativos y para auditorías de seguridad WiFi autorizadas. El uso de modo monitor y herramientas de captura de paquetes WiFi sin autorización explícita del propietario de la red es ilegal en la mayoría de los países.

Soy responsable únicamente del código que escribí. No me hago responsable del uso indebido que terceros hagan de esta herramienta. Usala de manera ética, legal y responsable.

---

## Autor

**Alan Newberry**
Desarrollado bajo el alias **44ghost44**

---

## Licencia

Este proyecto está licenciado bajo la [Licencia MIT](LICENSE).
