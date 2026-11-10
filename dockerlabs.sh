#!/bin/bash
# dockerlabs.sh - Lista y descarga máquinas de DockerLabs (https://dockerlabs.es)
# y sus writeups. Proyecto no oficial, sin relación con DockerLabs.
#
# Necesita: curl y python3 (vienen de serie en Kali).
# Los writeups solo se bajan si están en GitHub como archivo .md.

WEB="https://dockerlabs.es"
# Nombre con el que el script se presenta a la web, para que DockerLabs sepa de dónde vienen las peticiones
UA="descargador-maquinas-dockerlabs/1.0 (+https://github.com/luigi70289/descargador-maquinas-dockerlabs)"
VERDE="\e[32m"; ROJO="\e[31m"; AMARILLO="\e[33m"; AZUL="\e[34m"; FIN="\e[0m"

ayuda() {
    echo -e "\nUso: $0 [opciones]\n"
    echo -e "  -l               Lista todas las máquinas"
    echo -e "  -x <dificultad>  Lista las máquinas de una dificultad y te deja elegir una para descargar"
    echo -e "                   (muy-facil, facil, medio, dificil)"
    echo -e "  -xr <dificultad> Descarga una máquina al azar de esa dificultad y un writeup al azar de ella"
    echo -e "  -n <nombre>      Descarga la máquina con ese nombre"
    echo -e "  -w <nombre>      Descarga la máquina y te deja elegir uno de sus writeups de GitHub"
    echo -e "  -wr <nombre>     Descarga la máquina y un writeup al azar de ella"
    echo -e "  -e <num|autor>   Junto con -w: elige el writeup directamente (por número o por autor)"
    echo -e "  -h               Muestra esta ayuda\n"
    echo -e "Ejemplos:"
    echo -e "  $0 -l"
    echo -e "  $0 -x facil"
    echo -e "  $0 -xr facil"
    echo -e "  $0 -n trust"
    echo -e "  $0 -w trust"
    echo -e "  $0 -wr trust"
    echo -e "  $0 -w trust -e AndresChili"
    echo
}

# Quita mayúsculas, tildes y espacios para comparar textos.
# Ej: "Muy Fácil" -> "muy-facil"
normalizar() {
    echo "$1" | sed 's/Á/a/g; s/É/e/g; s/Í/i/g; s/Ó/o/g; s/Ú/u/g; s/Ñ/n/g' \
        | tr '[:upper:]' '[:lower:]' \
        | sed 's/á/a/g; s/é/e/g; s/í/i/g; s/ó/o/g; s/ú/u/g; s/ñ/n/g; s/[ _]/-/g'
}

# Programa de Python que lee la portada de DockerLabs
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

# Programa de Python que lee la lista de writeups y se queda solo con los
# que son un archivo .md en GitHub. Saca una línea por writeup:
# autor<TAB>enlace de GitHub<TAB>enlace para descargar el .md
read -r -d '' LEER_WRITEUPS <<'PY'
import sys, json, re
try:
    datos = json.load(sys.stdin)
except Exception:
    datos = []
vistos = set()
for w in datos:
    url = (w.get("url") or "").strip()
    m = re.match(r"^https://github\.com/([^/]+)/([^/]+)/blob/(.+\.md)$", url, re.I)
    if not m or url in vistos:
        continue
    vistos.add(url)
    raw = f"https://raw.githubusercontent.com/{m[1]}/{m[2]}/{m[3]}"
    autor = re.sub(r"[^A-Za-z0-9._-]", "_", w.get("name") or "anonimo")
    print(f"{autor}\t{url}\t{raw}")
PY

# Descarga la portada y guarda en CATALOGO una línea por máquina:
# id<TAB>dificultad<TAB>nombre
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

# Baja un writeup. Recibe su línea: autor<TAB>enlace<TAB>enlace del .md
bajar_writeup() {
    local autor url raw archivo
    IFS=$'\t' read -r autor url raw <<< "$1"
    archivo="${NOMBRE_MAQUINA// /_}_writeup_${autor}.md"
    if curl -A "$UA" -sfL -m 30 -o "$archivo" "$raw" && [ -s "$archivo" ]; then
        echo -e "${VERDE}[+] Writeup de $autor guardado: $archivo${FIN}\n"
        return 0
    fi
    rm -f "$archivo"
    echo -e "${AMARILLO}[!] No se pudo bajar el writeup de $autor ($url)${FIN}"
    return 1
}

# Prueba writeups al azar hasta que uno se descargue bien
bajar_al_azar() {
    local w
    while IFS= read -r w; do
        bajar_writeup "$w" && return 0
    done < <(echo "$1" | shuf)
    echo -e "${ROJO}[-] No se pudo bajar ningún writeup de $NOMBRE_MAQUINA.${FIN}"
    return 1
}

# Descarga un writeup (solo de GitHub) de una máquina.
writeup() {
    local linea id dif json lista total eleccion
    linea=$(buscar "$1") || return 1
    IFS=$'\t' read -r id dif NOMBRE_MAQUINA <<< "$linea"

    json=$(curl -A "$UA" -sfL -m 30 "$WEB/api/writeups/$(python3 -c 'import sys,urllib.parse;print(urllib.parse.quote(sys.argv[1]))' "$NOMBRE_MAQUINA")")
    lista=$(echo "$json" | python3 -c "$LEER_WRITEUPS")
    if [ -z "$lista" ]; then
        echo -e "${ROJO}[-] $NOMBRE_MAQUINA no tiene writeups en GitHub.${FIN}"
        return 1
    fi
    total=$(echo "$lista" | grep -c .)

    # -wr: uno al azar, sin enseñar la lista
    if [ -n "$AZAR" ]; then
        bajar_al_azar "$lista"
        return
    fi

    echo -e "\n${AZUL}[+]${FIN} Writeups de ${VERDE}$NOMBRE_MAQUINA${FIN} en GitHub ($total):"
    echo "$lista" | awk -F'\t' '{printf "  %3d) %-20s %s\n", NR, $1, $2}'

    eleccion=1
    if [ -n "$ELEGIDO" ]; then
        eleccion=$ELEGIDO
        # Si no es un número, buscamos el autor (sin mirar mayúsculas)
        if ! [[ "$eleccion" =~ ^[0-9]+$ ]]; then
            eleccion=$(echo "$lista" | awk -F'\t' -v a="$(echo "$ELEGIDO" | tr '[:upper:]' '[:lower:]')" \
                'tolower($1) == a {print NR; exit}')
            if [ -z "$eleccion" ]; then
                echo -e "${ROJO}[-] No hay ningún writeup de '$ELEGIDO' para $NOMBRE_MAQUINA.${FIN}"; return 1
            fi
        fi
    elif [ -t 0 ]; then
        read -rp $'\n¿Cuál quieres? (número, r = al azar, Enter = el 1): ' eleccion
        eleccion=${eleccion:-1}
        if [ "$eleccion" = "r" ]; then
            bajar_al_azar "$lista"
            return
        fi
    fi
    if ! [[ "$eleccion" =~ ^[0-9]+$ ]] || [ "$eleccion" -lt 1 ] || [ "$eleccion" -gt "$total" ]; then
        echo -e "${ROJO}[-] Número no válido.${FIN}"; return 1
    fi
    bajar_writeup "$(echo "$lista" | sed -n "${eleccion}p")"
}

# ---------- Programa principal ----------

for herramienta in curl python3 shuf; do
    command -v "$herramienta" >/dev/null || { echo -e "${ROJO}[-] Falta $herramienta. Instálalo con: sudo apt install $herramienta${FIN}"; exit 1; }
done

[ $# -eq 0 ] && { ayuda; exit 0; }

# "-wr" = "-w" con writeup al azar; "-xr" = máquina al azar de una dificultad
args=()
for a in "$@"; do
    case "$a" in
        -wr|-rw) args+=("-r" "-w") ;;
        -xr|-rx) args+=("-r" "-x") ;;
        *)       args+=("$a") ;;
    esac
done
set -- "${args[@]}"

LISTAR=""; DIFICULTAD=""; NOMBRE=""; WRITEUP=""; ELEGIDO=""; AZAR=""
while getopts ":lx:n:w:e:rh" opcion; do
    case $opcion in
        l) LISTAR=1 ;;
        x) DIFICULTAD=$(normalizar "$OPTARG") ;;
        n) NOMBRE=$OPTARG ;;
        w) WRITEUP=$OPTARG ;;
        e) ELEGIDO=$OPTARG ;;
        r) AZAR=1 ;;
        h) ayuda; exit 0 ;;
        :) echo -e "${ROJO}[-] A -$OPTARG le falta un valor.${FIN}"; ayuda; exit 1 ;;
        *) echo -e "${ROJO}[-] Opción no válida: -$OPTARG${FIN}"; ayuda; exit 1 ;;
    esac
done

if [ -n "$ELEGIDO" ] && [ -z "$WRITEUP" ]; then
    echo -e "${ROJO}[-] -e solo sirve junto con -w. Ejemplo: $0 -w trust -e 3${FIN}"; exit 1
fi
if [ -n "$AZAR" ] && [ -z "$WRITEUP" ] && [ -z "$DIFICULTAD" ]; then
    echo -e "${ROJO}[-] Usa -wr <máquina> o -xr <dificultad>. Ejemplo: $0 -xr facil${FIN}"; exit 1
fi

# -w y -wr también bajan la máquina (si no se pidió ya otra con -n)
if [ -n "$WRITEUP" ] && [ -z "$NOMBRE" ]; then
    NOMBRE=$WRITEUP
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

    if [ -n "$AZAR" ] && [ -z "$WRITEUP" ]; then
        # -xr: una máquina al azar de esa dificultad, con un writeup al azar
        elegida=$(echo "$filtradas" | shuf -n 1)
        IFS=$'\t' read -r _ _ elegida_nombre <<< "$elegida"
        echo -e "\n${AZUL}[+]${FIN} Máquina elegida al azar: ${VERDE}$elegida_nombre${FIN}"
        descargar "$elegida"
        writeup "$elegida_nombre"
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

if [ -n "$WRITEUP" ]; then
    writeup "$WRITEUP"
fi
