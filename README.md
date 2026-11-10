# descargador-maquinas-dockerlabs

Script en Bash para descargar máquinas de [DockerLabs](https://dockerlabs.es) desde la terminal,
junto con un writeup de cada una para cuando te atasques.

Puedes buscar las máquinas por nombre o por dificultad, o dejar que el script elija una al azar.

## Requisitos

- Linux (pensado para Kali)
- `curl`, `python3` y `shuf` (vienen de serie en Kali)
- `docker` y `unzip` para desplegar las máquinas

## Instalación

```bash
git clone https://github.com/luigi70289/descargador-maquinas-dockerlabs
cd descargador-maquinas-dockerlabs
chmod +x dockerlabs.sh
```

## Uso

| Comando | Qué hace |
|---|---|
| `./dockerlabs.sh -l` | Lista todas las máquinas con su dificultad |
| `./dockerlabs.sh -x <dificultad>` | Lista las máquinas de esa dificultad y te deja elegir una para descargar (`r` = una al azar) |
| `./dockerlabs.sh -xr <dificultad>` | Descarga una máquina al azar de esa dificultad y un writeup al azar de ella |
| `./dockerlabs.sh -n <nombre>` | Descarga solo la máquina |
| `./dockerlabs.sh -w <nombre>` | Descarga la máquina y te deja elegir uno de sus writeups |
| `./dockerlabs.sh -wr <nombre>` | Descarga la máquina y un writeup al azar |
| `./dockerlabs.sh -w <nombre> -e <número o autor>` | Descarga la máquina y el writeup que indiques, sin preguntar |
| `./dockerlabs.sh -h` | Muestra la ayuda |

Dificultades: `muy-facil`, `facil`, `medio` y `dificil`.

### Ejemplos

```bash
./dockerlabs.sh -x muy-facil            # ver las máquinas muy fáciles y elegir una
./dockerlabs.sh -xr facil               # una máquina fácil cualquiera con su writeup
./dockerlabs.sh -n trust                # solo la máquina Trust
./dockerlabs.sh -wr trust               # Trust y un writeup al azar
./dockerlabs.sh -w trust -e AndresChili # Trust y el writeup de AndresChili
```

No hace falta escribir mayúsculas ni tildes: `-n "perrito magico"` encuentra *Perrito Mágico*.
Si escribes solo una parte del nombre y hay varias máquinas que coinciden, el script te las enseña.

## Qué se descarga

Todo se guarda en la carpeta desde la que ejecutas el script:

- `<maquina>.zip`: la máquina. Dentro vienen `<maquina>.tar` y `auto_deploy.sh`.
- `<Maquina>_writeup_<autor>.md`: el writeup, en Markdown.

## Desplegar la máquina

```bash
unzip trust.zip
sudo bash auto_deploy.sh trust.tar
```

Cuando termina, te dice la IP de la máquina (normalmente `172.17.0.2`). Para pararla y borrarla,
pulsa `Ctrl+C` en esa terminal.

## Sobre los writeups

- Solo se descargan los writeups que están en GitHub como archivo `.md`. Los que son vídeos o están
  en otras webs (Medium, Notion, Google Drive…) se ignoran porque no se pueden bajar desde un script.
- Con `-wr` y `-xr`, si el writeup elegido falla (por ejemplo, porque su autor lo borró), el script
  prueba con otro al azar.
- Si una máquina no tiene writeups en GitHub, el script avisa y descarga la máquina igualmente.

Intenta resolver la máquina tú primero y abre el writeup solo si te atascas 😉

## Cómo funciona

El script lee la lista de máquinas de la página principal de dockerlabs.es, saca el enlace del `.zip`
de la página de descarga de cada máquina y pide los writeups a `dockerlabs.es/api/writeups/<máquina>`.
Si DockerLabs cambia su web, puede que el script deje de funcionar hasta que se actualice.

## Créditos

Las máquinas son de [DockerLabs](https://dockerlabs.es), creado por El Pingüino de Mario, y los writeups
son de sus autores. Este script solo facilita la descarga.
