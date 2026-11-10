# descargador-maquinas-dockerlabs

Script en Bash para descargar máquinas de [DockerLabs](https://dockerlabs.es) desde la terminal,
junto con un writeup de cada una para cuando te atasques. También incluye las máquinas gratuitas
de [BunkerLabs](https://dockerlabs.es/bunkerlabs).

Puedes buscar las máquinas por nombre o por dificultad, o dejar que el script elija una al azar.

> ⚠️ **Proyecto no oficial.** Este script no está hecho ni respaldado por DockerLabs. Úsalo respetando
> sus [condiciones de uso](https://dockerlabs.es/condiciones-uso).

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
| `./dockerlabs.sh -l` | Lista todas las máquinas con su dificultad (DockerLabs y las gratuitas de BunkerLabs) |
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

## Máquinas de BunkerLabs

BunkerLabs es la zona de DockerLabs para alumnos de algunas academias. La mayoría de sus máquinas
piden contraseña, pero tiene un [modo de prueba](https://dockerlabs.es/bunkerlabs/guest) público con
algunas gratuitas. El script entra en ese modo de prueba y añade esas máquinas a la lista.

- En la lista salen marcadas con `[BunkerLabs]`.
- Se buscan y se descargan igual que las demás: `./dockerlabs.sh -n graphy`.
- No tienen writeups. Con `-w` o `-wr` se descarga la máquina y el script avisa de que no hay writeup.
- Las máquinas que piden contraseña no aparecen.

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

## Uso responsable

- El script hace las mismas peticiones que harías tú con el navegador, y solo cuando lo ejecutas.
  No lo metas en bucles ni lo uses para descargar todas las máquinas de golpe: no sobrecargues
  los servidores de DockerLabs.
- Se identifica ante la web como `descargador-maquinas-dockerlabs`, para que el creador sepa de dónde
  vienen las peticiones.
- Las máquinas se descargan siempre del servidor oficial. No las vuelvas a subir a otros sitios.
- Los writeups son de sus autores: léelos para aprender, pero no los publiques como tuyos.
- Las máquinas son vulnerables a propósito. Despliégalas solo en tu equipo y nunca ataques sistemas
  reales sin permiso.
- Si el creador de DockerLabs pide que este script no se use o que cambie algo, se hará caso.

## Créditos

Las máquinas son de [DockerLabs](https://dockerlabs.es), creado por El Pingüino de Mario, y los writeups
son de sus autores. Este script solo facilita la descarga.
