<#

.SYNOPSIS

    EJEMPLOS

        ./script.sh --eliminar archivo.txt

        ./script.sh --eliminar /home/archivo.txt

        ./script.sh --eliminar /../Public/archivo.txt

        ./script.sh --recuperar archivo.txt

        ./script.sh --listar

        ./script.sh --vaciar

        CASO DE ARCHIVO CON NOMBRE REPETIDO AL RECUPERAR

        ./script.sh --recuperar Sisop

           1 - Sisop /home/usuario1/docs

           2 - Sisop /home/usuario1/descargas

           3 - Sisop /home/usuario1/imágenes

           ¿Que archivo desea recuperar? ___

        ACLARACION

        En caso de querer eliminar/recuperar archivos con espacios en sus nombres, como requisito se tiene que pasar la ruta o nombre del archivo entre comillas ('archivo con espacio.txt')

        ./ejercicio6.ps1 --eliminar 'archivo con espacio.txt'

        ./ejercicio6.ps1 --eliminar '/home/Mi Carpeta/archivo.txt'

        ./ejercicio6.ps1 --recuperar 'archivo con espacio.txt'

.DESCRIPTION

   El script permite emular el comportamiento del comando rm, pero utilizando el concepto de papelera de reciclaje, es decir que, al borrar un ARCHIVO se tenga la posibilidad de recuperarlo en el futuro.

.PARAMETER Path

   --eliminar <NombreArchivo> : path absoluto o relativo del archivo a eliminar (obligatorio)

   --listar : lista los archivos que se encuentran en la papelera y sus rutas originales

   --recuperar <NombreArchivo> : permite recuperar el archivo pasado por parametro (obligatorio), en el caso que existan dos archivos con el mismo nombre , el usuario tendra la posibilidad de elegir cual recuperar"

   --vaciar : permite vaciar la papelera de reciclaje, eliminando definitivamente todos los archivos

#>



[CmdletBinding(DefaultParameterSetName = '--listar')]

Param(

    [Parameter(ParameterSetName = '--listar')]

    [Parameter(ParameterSetName = '--vaciar')]

    [Parameter(ParameterSetName = '--eliminar')]

    [Parameter(ParameterSetName = '--recuperar')]

    [Parameter(Position = 0)]

    [String]$accion,

    [Parameter(Position = 1, Mandatory = $False)][String]$archivo

)





if (("$accion" -eq "--eliminar" -Or "$accion" -eq "--recuperar" -Or "$accion" -eq "--vaciar" -Or "$accion" -eq "--listar"))
{

    if (("$accion" -eq "--eliminar" -Or "$accion" -eq "--recuperar") -And (!$archivo))
    {

        Write-Host "Proporcione valores para los parametros siguientes:"

        $archivo = Read-Host "Archivo"

    }

    $actual = pwd;

    cd $home

    $rutaHome = pwd;

    cd $actual

    $rutaPapelera = "$rutaHome/Papelera.zip"

    $rutaArchivosOriginales = "$rutaHome/rutasOriginales.txt"

    $archivoSalva = "$rutaHome/archivoSalva.txt"



    function verificarRutaPapelera() {

        return -not (Test-Path $rutaPapelera);

    }



    function agregarArchivoEnPapelera() {

        param([string]$archivoAEliminar)



        if (verificarRutaPapelera)
        {

            Compress-Archive -Path $archivoAEliminar -DestinationPath $rutaPapelera

        }

        else
        {

            Compress-Archive -Path $archivoAEliminar -Update $rutaPapelera

        }

    }



    function verificarArchivoRutasOriginales() {

        if (-not (Test-Path $rutaArchivosOriginales)) 
        {

            New-Item -Path $rutaArchivosOriginales -ItemType File | out-null

        }

    }



    verificarArchivoRutasOriginales



    if ($accion -eq "--listar")
    {

        [string[]]$arrayArchivosARecuperar = Get-Content -Path $rutaArchivosOriginales

        for ($i = 0; $i -le $arrayArchivosARecuperar.Length - 1; $i++)
        {

            $nombreArch = $arrayArchivosARecuperar[$i].Split("-")[0]

            $rutaOrig = $arrayArchivosARecuperar[$i].Split("-")[1]

            Write-Host "$nombreArch $rutaOrig"

        }

    

    }



    if ($accion -eq "--eliminar")
    {

        if (-not (Test-Path $archivo)) 
        {

            Write-Host "No existe el archivo a eliminar"

        }

        else
        {

            $fullPathArchivo = Get-ChildItem -Path $archivo | % { $_.FullName }

            $pathWithOutArchive = Split-Path -Path $fullPathArchivo

            $nameArchive = Get-ChildItem -Path $archivo | % { $_.Name }

            $fecha = Get-ChildItem -Path $archivo | % { $_.CreationTime }

            $fecha = $fecha -replace (" ", "") -replace ("/", "") -replace (":", "")

            Add-Content -Value "$nameArchive-$pathWithOutArchive-$fecha" -Path $rutaArchivosOriginales 

            Rename-Item -Path $fullPathArchivo -NewName "$nameArchive-$fecha"

            agregarArchivoEnPapelera -archivoAEliminar "$fullPathArchivo-$fecha"

            Remove-Item -Path "$fullPathArchivo-$fecha";

        }



    }



    if ($accion -eq "--recuperar")
    {

        [string[]]$arrayArchivosARecuperar = Get-Content -Path $rutaArchivosOriginales | Select-String -Pattern $archivo

        if ($arrayArchivosARecuperar.Length -eq 0)
        {

            Write-Host "No existe el archivo a recuperar"

        }

        else
        {

            if ($arrayArchivosARecuperar.Length -eq 1) {

                $nombreArchivoYRuta = $arrayArchivosARecuperar[0];

                $nombreArch = $nombreArchivoYRuta.Split("-")[0]

                $rutaOrig = $nombreArchivoYRuta.Split("-")[1]

                $fechaCreacionArchivo = $nombreArchivoYRuta.Split("-")[2]



                $nombreComoEstaEnPapelera = "$nombreArch-$fechaCreacionArchivo"



                if (-not (Test-Path "$rutaOrig/$nombreArch")) 
                {

                    Add-Type -Assembly System.IO.Compression.FileSystem

                    $zipFile = [IO.Compression.ZipFile]::OpenRead($rutaPapelera)

                    $zipFile.Entries | where { $_.Name -like $nombreComoEstaEnPapelera } | out-null

                    Write-Host $rutaOrig

                    [System.IO.Compression.ZipFileExtensions]::ExtractToFile($zipFile.Entries[0], "$rutaOrig/$nombreComoEstaEnPapelera", $true) 

                    $zipFile.Dispose()

                    Rename-Item -Path "$rutaOrig/$nombreComoEstaEnPapelera" -NewName "$nombreArch"

                    $nuevaInfo = Get-Content $rutaArchivosOriginales | Where-Object { $_ -notmatch $fechaCreacionArchivo }

                    Set-Content -value $nuevaInfo -Path $rutaArchivosOriginales

                }

                else
                {

                    #no se puede recuperar ya existe uno con el mismo nombre

                    Write-Host "No se puede recuperar, ya que existe un archivo con el mismo nombre."

                    exit;

                }

            }

            else
            {

                for ($i = 0; $i -le $arrayArchivosARecuperar.Length - 1; $i++)
                {

                    $prueba = $arrayArchivosARecuperar[$i].Split("-")[0]

                    if ("$prueba" -eq "$archivo")
                    {

                        $numero = $i + 1 

                        $nombreArch = $arrayArchivosARecuperar[$i].Split("-")[0]

                        $rutaOrig = $arrayArchivosARecuperar[$i].Split("-")[1]

                        Write-Host $numero - $nombreArch $rutaOrig

                    }

                }

                $numeroOpcionElegida = Read-Host "Que archivo desea recuperar?"

                if ($numeroOpcionElegida -le 0 -Or $numeroOpcionElegida -gt $arrayArchivosARecuperar.Length)
                {

                    Write-Host "ERROR-Numero no valido."

                    exit;

                }

                $nombreArchivoYRuta = $arrayArchivosARecuperar[$numeroOpcionElegida - 1];

                $nombreArch = $nombreArchivoYRuta.Split("-")[0]

                $rutaOrig = $nombreArchivoYRuta.Split("-")[1]

                $fechaCreacionArchivo = $nombreArchivoYRuta.Split("-")[2]



                $nombreComoEstaEnPapelera = "$nombreArch-$fechaCreacionArchivo"



                if (-not (Test-Path "$rutaOrig/$nombreArch")) 
                {

                    Add-Type -Assembly System.IO.Compression.FileSystem

                    $zipFile = [IO.Compression.ZipFile]::OpenRead($rutaPapelera)

                    $zipFile.Entries | where { $_.Name -like $nombreComoEstaEnPapelera } | out-null

                    [System.IO.Compression.ZipFileExtensions]::ExtractToFile($zipFile.Entries[0], "$rutaOrig/$nombreComoEstaEnPapelera", $true) 

                    $zipFile.Dispose()

                    Rename-Item -Path "$rutaOrig/$nombreComoEstaEnPapelera" -NewName "$nombreArch"

                    $nuevaInfo = Get-Content $rutaArchivosOriginales | Where-Object { $_ -notmatch $fechaCreacionArchivo }

                    Set-Content -value $nuevaInfo -Path $rutaArchivosOriginales

                }

                else
                {

                    Write-Host "No se puede recuperar, ya que existe un archivo con el mismo nombre."

                    exit;

                }



            }

        }

   

    }



    if ($accion -eq "--vaciar")
    {

        if ([String]::IsNullOrWhiteSpace((Get-content $rutaArchivosOriginales)))
        {

            Write-Host "La papelera ya se encuentra vacia"

        }

        else
        {

            Remove-item $rutaPapelera

            New-Item -Path $archivoSalva -ItemType File | out-null

            Compress-Archive -Path $archivoSalva -DestinationPath $rutaPapelera

            Clear-Content $rutaArchivosOriginales

            Remove-Item -Path $archivoSalva

        }



    }



}

else
{

    Write-Host "COMANDOS INCORRECTOS - EJECUTE LA AYUDA"

    exit;

}

