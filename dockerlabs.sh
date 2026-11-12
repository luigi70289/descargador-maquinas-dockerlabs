#!/bin/bash
# dockerlabs.sh - Lista y descarga máquinas de DockerLabs (https://dockerlabs.es).
# Proyecto no oficial, sin relación con DockerLabs.
#
# Necesita: curl y python3 (vienen de serie en Kali).

WEB="https://dockerlabs.es"
# Nombre con el que el script se presenta a la web, para que DockerLabs sepa de dónde vienen las peticiones
UA="descargador-maquinas-dockerlabs/1.0 (+https://github.com/luigi70289/descargador-maquinas-dockerlabs)"
VERDE="\e[32m"; ROJO="\e[31m"; AMARILLO="\e[33m"; AZUL="\e[34m"; FIN="\e[0m"

ayuda() {
    echo -e "\nUso: $0 [opciones]\n"
    echo -e "  -l               Lista todas las máquinas"
    echo -e "  -x <dificultad>  Lista las máquinas de una dificultad y te deja elegir una para descargar"
    echo -e "                   (muy-facil, facil, medio, dificil)"
    echo -e "  -xr <dificultad> Descarga una máquina al azar de esa dificultad"
    echo -e "  -n <nombre>      Descarga la máquina con ese nombre"
    echo -e "  -h               Muestra esta ayuda\n"
    echo -e "Ejemplos:"
    echo -e "  $0 -l"
    echo -e "  $0 -x facil"
    echo -e "  $0 -xr facil"
    echo -e "  $0 -n trust"
    echo
}

# Quita mayúsculas, tildes y espacios para comparar textos.
# Ej: "Muy Fácil" -> "muy-facil"
normalizar() {
    echo "$1" | sed 's/Á/a/g; s/É/e/g; s/Í/i/g; s/Ó/o/g; s/Ú/u/g; s/Ñ/n/g' \
        | tr '[:upper:]' '[:lower:]' \
        | sed 's/á/a/g; s/é/e/g; s/í/i/g; s/ó/o/g; s/ú/u/g; s/ñ/n/g; s/[ _]/-/g'
}

# Programa de Python que lee la portada de DockerLabs. Saca una línea por máquina:
# id<TAB>dificultad<TAB>nombre<TAB>nombre-sin-tildes
read -r -d '' LEER_PORTADA <<'PY'
import sys, re, html, json, unicodedata
s = html.unescape(sys.stdin.read())
texto = r'"(?:[^"\\]|\\.)*"'
patron = r"presentacion\((" + texto + r"), (" + texto + r").*?/maquinas/(\d+)/descargar"
for nombre, dif, mid in re.findall(patron, s, re.S):
    nombre = json.loads(nombre)
    clave = unicodedata.normalize("NFKD", nombre).encode("ascii", "ignore").decode()
    clave = clave.lower().replace(" ", "-").replace("_", "-")
    print(f"{mid}\t{json.loads(dif)}\t{nombre}\t{clave}")
PY

# Descarga la portada y guarda en CATALOGO una línea por máquina:
# id<TAB>dificultad<TAB>nombre<TAB>nombre-sin-tildes
cargar_catalogo() {
    local html
    if ! html=$(curl -A "$UA" -sfL -m 30 "$WEB"); then
        echo -e "${ROJO}[-] No se pudo conectar con DockerLabs.${FIN}" >&2
        exit 1
    fi
    CATALOGO=$(echo "$html" | python3 -c "$LEER_PORTADA")
    if [ -z "$CATALOGO" ]; then
        echo -e "${ROJO}[-] No se pudo leer la lista de máquinas (¿ha cambiado la web?).${FIN}" >&2
        exit 1
    fi
}

catalogo() { echo "$CATALOGO"; }

# Imprime la lista con colores. Recibe líneas id<TAB>dificultad<TAB>nombre
imprimir() {
    local i=0 id dif nombre color
    while IFS=$'\t' read -r id dif nombre _; do
        i=$((i + 1))
        case "$(normalizar "$dif")" in
            muy-facil) color=$AZUL ;;
            facil)     color=$VERDE ;;
            medio)     color=$AMARILLO ;;
            *)         color=$ROJO ;;
        esac
        # Relleno a mano: printf cuenta bytes y las tildes ocupan 2
        printf "  %3d) %s%*s ${color}%s${FIN}\n" "$i" "$nombre" $((30 - ${#nombre})) "" "$dif"
    done
}

# Busca una máquina por nombre (sin mirar mayúsculas). Devuelve su línea del catálogo.
buscar() {
    local busca exacta parecidas
    busca=$(normalizar "$1")
    exacta=$(catalogo | awk -F'\t' -v b="$busca" '$4 == b' | cut -f1-3)
    if [ -n "$exacta" ]; then echo "$exacta" | head -1; return 0; fi

    parecidas=$(catalogo | awk -F'\t' -v b="$busca" 'index($4, b)' | cut -f1-3)
    if [ "$(echo "$parecidas" | grep -c .)" -eq 1 ]; then
        echo "$parecidas"; return 0
    fi
    if [ -n "$parecidas" ]; then
        echo -e "${AMARILLO}[!] Hay varias máquinas que se parecen a '$1':${FIN}" >&2
        echo "$parecidas" | imprimir >&2
    else
        echo -e "${ROJO}[-] No existe ninguna máquina llamada '$1'. Usa -l para ver la lista.${FIN}" >&2
    fi
    return 1
}

# Descarga el .zip de una máquina. Recibe su línea del catálogo.
descargar() {
    local id dif nombre zip archivo
    IFS=$'\t' read -r id dif nombre <<< "$1"
    echo -e "\n${AZUL}[+]${FIN} Buscando la descarga de ${VERDE}$nombre${FIN} ($dif)..."
    zip=$(curl -A "$UA" -sfL -m 30 "$WEB/maquinas/$id/descargar" \
        | grep -oE 'https://gestion-maquinas\.dockerlabs\.es/dl/[^"]+\.zip' | head -1)
    if [ -z "$zip" ]; then
        echo -e "${ROJO}[-] No encontré el enlace de descarga de $nombre.${FIN}"
        return 1
    fi
    archivo=$(basename "$zip")
    if curl -A "$UA" -fL --progress-bar -o "$archivo" "$zip"; then
        echo -e "${VERDE}[+] Descargada: $archivo${FIN}"
        echo -e "    Para empezar:"
        echo -e "      unzip $archivo"
        echo -e "      sudo bash auto_deploy.sh ${archivo%.zip}.tar\n"
    else
        rm -f "$archivo"
        echo -e "${ROJO}[-] Falló la descarga de $zip${FIN}"
        return 1
    fi
}

# ---------- Programa principal ----------

for herramienta in curl python3 shuf; do
    command -v "$herramienta" >/dev/null || { echo -e "${ROJO}[-] Falta $herramienta. Instálalo con: sudo apt install $herramienta${FIN}"; exit 1; }
done

[ $# -eq 0 ] && { ayuda; exit 0; }

# "-xr" = máquina al azar de una dificultad
args=()
for a in "$@"; do
    case "$a" in
        -xr|-rx) args+=("-r" "-x") ;;
        *)       args+=("$a") ;;
    esac
done
set -- "${args[@]}"

LISTAR=""; DIFICULTAD=""; NOMBRE=""; AZAR=""
while getopts ":lx:n:rh" opcion; do
    case $opcion in
        l) LISTAR=1 ;;
        x) DIFICULTAD=$(normalizar "$OPTARG") ;;
        n) NOMBRE=$OPTARG ;;
        r) AZAR=1 ;;
        h) ayuda; exit 0 ;;
        :) echo -e "${ROJO}[-] A -$OPTARG le falta un valor.${FIN}"; ayuda; exit 1 ;;
        *) echo -e "${ROJO}[-] Opción no válida: -$OPTARG${FIN}"; ayuda; exit 1 ;;
    esac
done

if [ -n "$AZAR" ] && [ -z "$DIFICULTAD" ]; then
    echo -e "${ROJO}[-] -xr necesita una dificultad. Ejemplo: $0 -xr facil${FIN}"; exit 1
fi

cargar_catalogo

if [ -n "$LISTAR" ]; then
    echo -e "\n${AZUL}[+]${FIN} Máquinas de DockerLabs:\n"
    catalogo | sort -t$'\t' -k3,3f | imprimir
    echo
fi

if [ -n "$DIFICULTAD" ]; then
    case "$DIFICULTAD" in
        muy-facil|facil|medio|dificil) ;;
        *) echo -e "${ROJO}[-] Dificultad no válida. Usa: muy-facil, facil, medio o dificil${FIN}"; exit 1 ;;
    esac
    filtradas=$(catalogo | while IFS=$'\t' read -r id dif nombre _; do
        [ "$(normalizar "$dif")" = "$DIFICULTAD" ] && printf '%s\t%s\t%s\n' "$id" "$dif" "$nombre"
    done | sort -t$'\t' -k3,3f)
    total=$(echo "$filtradas" | grep -c .)

    if [ -n "$AZAR" ]; then
        # -xr: una máquina al azar de esa dificultad
        elegida=$(echo "$filtradas" | shuf -n 1)
        IFS=$'\t' read -r _ _ elegida_nombre <<< "$elegida"
        echo -e "\n${AZUL}[+]${FIN} Máquina elegida al azar: ${VERDE}$elegida_nombre${FIN}"
        descargar "$elegida"
        exit
    fi

    echo -e "\n${AZUL}[+]${FIN} Máquinas de dificultad '$DIFICULTAD' ($total):\n"
    [ "$total" -gt 0 ] && echo "$filtradas" | imprimir

    if [ -t 0 ] && [ "$total" -gt 0 ]; then
        read -rp $'\nNúmero de la máquina a descargar (r = una al azar, Enter = ninguna): ' eleccion
        [ "$eleccion" = "r" ] && eleccion=$(( RANDOM % total + 1 ))
        if [[ "$eleccion" =~ ^[0-9]+$ ]] && [ "$eleccion" -ge 1 ] && [ "$eleccion" -le "$total" ]; then
            descargar "$(echo "$filtradas" | sed -n "${eleccion}p")"
        elif [ -n "$eleccion" ]; then
            echo -e "${ROJO}[-] Número no válido.${FIN}"
        fi
    fi
    echo
fi

if [ -n "$NOMBRE" ]; then
    linea=$(buscar "$NOMBRE") && descargar "$linea"
fi
