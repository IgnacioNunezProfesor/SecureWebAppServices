Param(
    [Parameter(Mandatory = $true)]
    [string]$EnvFile
)

if (Get-Module 'env') { 
    Remove-Module 'env' -Force 
} 
Import-Module .\scripts\ps1\mods\env.psm1 -Force

$requiredVars = @(
    "DOCKERFILE",
    "DOCKER_IMAGE_NAME",
    "HTTP_APACHE2_LOCAL_CONF_DIR",
    "HTTP_APACHE2_LOCAL_CONFD_DIR",
    "HTTP_APACHE2_SERVER_CONF_DIR",
    "HTTP_APACHE2_SERVER_CONFD_DIR",
    "HTTP_APACHE2_SERVER_PORT",
    "HTTP_APACHE2_LOCAL_PORT",
    "HTTP_APACHE2_LOCAL_DEFAULT_FOLDER",
    "HTTP_APACHE2_SERVER_DEFAULT_FOLDER"
)

Write-Host "Loading environment variables from: $envFile"
$envVars = Get-EnvVarsFromFile -envFile $EnvFile
if (-not $envVars) {
    Write-Error "No se pudieron cargar las variables de entorno desde $EnvFile"
    exit 1
}

if (-not (Test-EnvVars -envVars $envVars -requiredVars $requiredVars)) {
    Write-Error "Validation failed. Please check your environment file and try again."
    exit 1
}

# Convertirlas a --build-arg
$buildArgs = EnvVarsToBuildArgs -envVars $envVars

# Construir parámetros docker
$dockerParams = @(
    'build'
) 
if ($buildArgs.Count -gt 0) { 
    $dockerParams += $buildArgs 
} 



$dockerParams += @( 
    '--no-cache', 
    '-f', $envVars.DOCKERFILE, 
    '-t', $envVars.DOCKER_IMAGE_NAME, '.' 
) 

$dockerParamsStr = $dockerParams -join ' ' 
Write-Host "Ejecutando: docker $dockerParamsStr" 
docker @dockerParams 
$code = $LASTEXITCODE 
if ($code -ne 0) { 
    Write-Error "docker build falló con código $code" 
    exit $code 
} 
Write-Host "Build completado exitosamente."