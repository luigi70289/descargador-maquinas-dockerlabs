# descargador-maquinas-dockerlabs

Script en Bash para descargar máquinas de [DockerLabs](https://dockerlabs.es) desde la terminal.

Puedes buscar las máquinas por nombre o por dificultad, o dejar que el script elija una al azar.

> ⚠️ **Proyecto no oficial.** Este script no está hecho ni respaldado por DockerLabs. Úsalo respetando
> sus [condiciones de uso](https://dockerlabs.es/condiciones-uso).

## Requisitos

- Linux (pensado para Kali)
- `curl` y `python3` (vienen de serie en Kali)
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
| `./dockerlabs.sh -xr <dificultad>` | Descarga una máquina al azar de esa dificultad |
| `./dockerlabs.sh -n <nombre>` | Descarga la máquina con ese nombre |
| `./dockerlabs.sh -h` | Muestra la ayuda |

Dificultades: `muy-facil`, `facil`, `medio` y `dificil`.

### Ejemplos

```bash
./dockerlabs.sh -x muy-facil   # ver las máquinas muy fáciles y elegir una
./dockerlabs.sh -xr facil      # una máquina fácil cualquiera
./dockerlabs.sh -n trust       # la máquina Trust
```

No hace falta escribir mayúsculas ni tildes: `-n "perrito magico"` encuentra *Perrito Mágico*.
Si escribes solo una parte del nombre y hay varias máquinas que coinciden, el script te las enseña.

## Qué se descarga

Todo se guarda en la carpeta desde la que ejecutas el script, como `<maquina>.zip`.
Dentro del `.zip` vienen `<maquina>.tar` y `auto_deploy.sh`.

## Desplegar la máquina

```bash
unzip trust.zip
sudo bash auto_deploy.sh trust.tar
```

Cuando termina, te dice la IP de la máquina (normalmente `172.17.0.2`). Para pararla y borrarla,
pulsa `Ctrl+C` en esa terminal.

## Uso responsable

- El script hace las mismas peticiones que harías tú con el navegador, y solo cuando lo ejecutas.
  No lo metas en bucles ni lo uses para descargar todas las máquinas de golpe: no sobrecargues
  los servidores de DockerLabs.
- Se identifica ante la web como `descargador-maquinas-dockerlabs`, para que el creador sepa de dónde
  vienen las peticiones.
- Las máquinas se descargan siempre del servidor oficial. No las vuelvas a subir a otros sitios.
- Las máquinas son vulnerables a propósito. Despliégalas solo en tu equipo y nunca ataques sistemas
  reales sin permiso.
- Si el creador de DockerLabs pide que este script no se use o que cambie algo, se hará caso.

## Cómo funciona

El script lee la lista de máquinas de la página principal de dockerlabs.es y saca el enlace del `.zip`
de la página de descarga de cada máquina. Si DockerLabs cambia su web, puede que el script deje de
funcionar hasta que se actualice.

## Créditos

Las máquinas son de [DockerLabs](https://dockerlabs.es), creado por El Pingüino de Mario.
Este script solo facilita la descarga.
