
<#
.SYNOPSIS
    .
.DESCRIPTION
    El script puede ejecutarse de la/s siguiente/s manera/s: 
    ./ejercicio3.ps1 -c <directorio a monitorear>

    ./ejercicio3.ps1 -c <directorio a monitorear> -a <acciones a realizar>

    ./ejercicio3.ps1 -c <directorio a monitorear> -a <acciones a realizar> -s <salida de la compilacion>

    El Script recibe los siguientes parametros:
     -c: ruta del directorio a monitorear. Se deben monitorear también dentro de los subdirectorios.
    
     -a: una lista de acciones separadas con coma a ejecutar cada vez que haya un cambio en el directorio a monitorear. Las acciones puede ser:
         o  “listar”: muestra por pantalla los nombres de los archivos que sufrieron cambios
            (archivos creados, modificados, renombrados, borrados).
         o  “peso”: muestra por pantalla el peso de los archivos que sufrieron cambios.
         o  “compilar”: compila los archivos dentro del directorio pasado en “-c”. Para la
            resolución de este ejercicio se va a considerar “compilar” a concatenar el contenido
            de todos los archivos en uno solo. Este archivo debe estar localizado en un
            directorio llamado “bin” en el mismo directorio en donde se encuentra el script.
         o  “publicar”: copia el archivo compilado (el generado con la opción “compilar”) a un
            directorio pasado como parámetro “-s”. Esta opción no se puede usar sin la opción
            “compilar”.
        
     -s: ruta del directorio utilizado por la acción “publicar”. Sólo es obligatorio si se envía
         “publicar” como acción en “-a”.

    Para eliminar los monitoreos actuales ejecutar la siguiente linea de powershell:
        Get-eventSubscriber | Unregister-Event     
.PARAMETER Path
    El Script recibe los siguientes parametros:
     -c: ruta del directorio a monitorear. Se deben monitorear también dentro de los subdirectorios.
    
     -a: una lista de acciones separadas con coma a ejecutar cada vez que haya un cambio en el directorio a monitorear. Las acciones puede ser:
         o  “listar”: muestra por pantalla los nombres de los archivos que sufrieron cambios
            (archivos creados, modificados, renombrados, borrados).
         o  “peso”: muestra por pantalla el peso de los archivos que sufrieron cambios.
         o  “compilar”: compila los archivos dentro del directorio pasado en “-c”. Para la
            resolución de este ejercicio se va a considerar “compilar” a concatenar el contenido
            de todos los archivos en uno solo. Este archivo debe estar localizado en un
            directorio llamado “bin” en el mismo directorio en donde se encuentra el script.
         o  “publicar”: copia el archivo compilado (el generado con la opción “compilar”) a un
            directorio pasado como parámetro “-s”. Esta opción no se puede usar sin la opción
            “compilar”.
        
     -s: ruta del directorio utilizado por la acción “publicar”. Sólo es obligatorio si se envía
         “publicar” como acción en “-a”.

#>

Param(
     [Parameter(Mandatory=$true)]
     [String] $c,
 
     [Parameter()]
      $a,

     [Parameter()]
     [String] $s
 )

$global:accionesActivadas=New-Object System.Collections.ArrayList;
$global:publicar=$false;

foreach ($i in $a) {
    if($i -eq "listar" -or $i -eq "peso" -or $i -eq "publicar" -or $i -eq "compilar"){
            $global:accionesActivadas.Add($i) | out-null;
    }else{
        Write-Host "Error, la accion $i no esta permitida"
            exit
    }
}



if(-not ( $s -eq "" )){
    if(-not ($global:accionesActivadas -contains "publicar")){
        Write-Host "no es necesario el parametro -s si no se incluye la accion publicar"
        exit
    }
}

if($global:accionesActivadas -contains "publicar"){
    $global:publicar=$true;
    if(-not ($global:accionesActivadas -contains "compilar")){
        Write-Host "no se puede publicar sin compilar"
        exit
    }
    if(( $s -eq "" )){
        Write-Host "necesita especificar una ruta en -s"
        exit
    }
}

$global:pathDir=$c;
$global:pathPublicar=$s

 
#ruta real
if(-not (Test-Path -Path "$global:pathDir")){
    Write-Host "No existe el directorio a observar"
    return
} 
$global:pathDir=(Get-Item "$global:pathDir")

$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $global:pathDir
$watcher.IncludeSubdirectories= $true;
$watcher.EnableRaisingEvents = $true;
 
 
$action=
{
    Write-Host " " 
    $name = $Event.SourceEventArgs.Name;
    $changeType = $Event.SourceEventArgs.ChangeType
    $path = $Event.SourceEventArgs.FullPath
    $pathOld = $Event.SourceEventArgs.OldFullPath

    Write-Host "Se detecto un cambio en: $name"
 
    foreach ($i in $global:accionesActivadas) {
        switch ($i) {
            'listar' { 
                Write-Host "Evento: $changeType"
                if ($changeType -eq "Changed"){
                    Write-Host "Path anterior: $pathOld"
                    Write-Host "Path nuevo: $path"
                }
             }
            'peso' { 
                $size=(Get-Item $name).length
                Write-Host "Peso: $size"
             }
            'compilar' { 
                Write-Host "Compilando"
                if (-not (Test-Path "./bin"))
                {
                    New-Item "./bin" -itemType Directory
                }
                if (-not (Test-Path "./bin/compilar"))
                {
                    New-Item "./bin/compilar" -itemType File
                }
                clear-content "./bin/compilar"
                Get-ChildItem -Recurse -Path $global:pathDir | ForEach-Object -Process {
                    Get-Content $_ | Out-File "./bin/compilar" –Append
                }
                if ($global:publicar){
                    if (-not (Test-Path $global:pathPublicar)){
                        New-Item $global:pathPublicar -itemType Directory
                    }
                    Copy-Item -Path "./bin/compilar" -Destination $global:pathPublicar
                }
             }
            Default {}
        }
    }
}

foreach ($i in $(ls -al $global:pathDir)) {
    if ($i.EndsWith(" .") -and (-not ($i.Substring(1,1) -eq "r"))){
            Write-Host "no se puede observar una carpeta sobre la cual no se tiene permisos"
            exit
    }
}

    $eventos = Get-EventSubscriber
    ForEach ($evento in $eventos) {
        switch ($evento.SourceIdentifier){
            FSCreate-$global:pathDir{
                Write-Host "Error ya se esta observando ese directorio"
                return;
            }
            FSChange-$global:pathDir{
                Write-Host "Error ya se esta observando ese directorio"
                return;
            }
            FSDelete-$global:pathDir{
                Write-Host "Error ya se esta observando ese directorio"
                return;
            }
            FSRename-$global:pathDir{
                Write-Host "Error ya se esta observando ese directorio"
                return;
            }
        }
    }
Register-ObjectEvent -InputObject $watcher -EventName Created -Action $action -SourceIdentifier FSCreate-$global:pathDir
Register-ObjectEvent -InputObject $watcher -EventName Changed -Action $action -SourceIdentifier FSChange-$global:pathDir
Register-ObjectEvent -InputObject $watcher -EventName Deleted -Action $action -SourceIdentifier FSDelete-$global:pathDir
Register-ObjectEvent -InputObject $watcher -EventName Renamed -Action $action -SourceIdentifier FSRename-$global:pathDir
 
