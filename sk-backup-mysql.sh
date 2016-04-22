#!/bin/bash
# Respaldamos todas las bases de datos del servidor, 
# Creamos un archivo con el log, 
# 
# v0.4 Cambios menores, añadido conteo de bases de datos.
# 21 de dic del 2014
# Maks Skamasle | Skamasle.com | yo@skamasle.com | twiter @skamasle
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details. http://www.gnu.org/licenses/
# Bajo licencia GNU GPL http://www.gnu.org/licenses/ se distribuye sin ninguna garantía.
# Actualizaciones  y más: http://kb.skamasle.com/2014/respaldar-todas-las-bases-de-datos-backup-all-data-bases-plesk-cpanel-onfig/
backupin=/root/sk-mysqldump # Ruta para guardar los backup
expira=5 	# Número de días que se retienen los backups de MSYQL en local (archivos mayores a 2 días se borran antes del backup)
# Datos de mysql.
# Tipo de servidor.
# Detectamos el tipo de servidor, plesk, cpanel o ispconfig para obtener automaticamente la clave de la base de datos.
# Si el servidor no es plesk, cpanel o ispconfig dejamos como "normal" y definimos la clave en la parte de abajo en mypass.
#################
#################
servertype=plesk # Opciones: normal, cpanel, plesk, ipsconfig, directadmin
#################
#################
myuser="root"
mypass="pass" # Root Password
myhost="localhost"

if [ $servertype = plesk ]; then
	myuser="admin"	
	mypass=`cat /etc/psa/.psa.shadow` 
fi
if [ $servertype = cpanel ]; then
	mypass=`cat /root/.my.cnf |grep password | cut -d '=' -f2`
fi
if [ $servertype = ispconfig ]; then
	mypass=`cat /usr/local/ispconfig/server/lib/mysql_clientdb.conf |grep password | cut -d "'" -f2`
fi
if [ $servertype = directadmin ]; then
	myuser="da_admin"
	mypass=`cat /usr/local/directadmin/conf/mysql.conf |grep passwd | cut -d "=" -f2`
fi

MKDIR=/bin/mkdir
TOUCH=/bin/touch
logfile=/root/SK-BackupLog.txt
fecha=$(/bin/date)
if [ ! -d $backupin ]; then
	$MKDIR $backupin 
else
	find $backupin -type d -mtime +$expira | xargs rm -Rf
	
fi
if [ ! -e $logfile ]; then
	$TOUCH $logfile
fi
carpetabk=$backupin/`date +%Y-%m-%d-h%H%M-%S`

if [ ! -d $carpetabk ]; then
	$MKDIR -p $carpetabk
fi
# no hace falta cambiarlo
lists=$(echo "show databases;" | mysql -h $myhost -u $myuser -p$mypass | grep -v Database | grep -v information_schema | grep -v performance_schema | grep -v phpmyadmin )

echo "Comenzando el respaldo de las bases de datos" >> $logfile
tput setaf 1
tput bold
echo "Comenzando el respaldo de las bases de datos"
tput sgr0 
echo $fecha >> $logfile
C=0
for db in $lists
do
		tput setaf 2	
 	echo "Respaldo base de datos $db"
	mysqldump -h $myhost -u$myuser -p$mypass --opt $db > $carpetabk/$db.sql 2>/tmp/skdump_errorlog
	echo "Respaldando $db" >> $logfile
	tput setaf 3	
	echo "Comprimiendo (gzip) base de datos --- $db"
	tput sgr0	
	gzip $carpetabk/$db.sql
	((C++))
done
echo "Backup completo, se respaldaron $C Bases de Datos!" >> $logfile
echo $fecha >> $logfile
echo "Puedes revisar el log en $logfile y el errorlog en /tmp/skdump_errorlog"
tput setaf 2
echo "Se respaldaron $C Bases de datos"
tput sgr0
