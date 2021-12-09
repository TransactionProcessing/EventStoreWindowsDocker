# escape=`
FROM mcr.microsoft.com/windows/servercore:ltsc2019 AS downloader

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

ENV ES_VERSION="21.2.0" `
    ES_HOME="C:\eventstore"

# ENV chocolateyUseWindowsCompression false

# RUN powershell -Command `
#         iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1')); `
#         choco feature disable --name showDownloadProgress

# RUN choco install eventstore-oss

RUN Invoke-WebRequest "https://github.com/EventStore/Downloads/raw/master/win/EventStore-OSS-Windows-2019-v$($env:ES_VERSION).zip" -OutFile 'eventstore.zip' -UseBasicParsing; `
    Expand-Archive eventstore.zip -DestinationPath $env:ES_HOME ;

FROM mcr.microsoft.com/windows/servercore:ltsc2019
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop';"]

ENV ES_VERSION="21.2.0" `
ES_HOME="C:\eventstore" `
DOTNET_RUNNING_IN_CONTAINER=true

EXPOSE 1113 2113

VOLUME C:\Data
VOLUME C:\Logs

RUN New-Item -Path Config -ItemType Directory | Out-Null

WORKDIR $ES_HOME
COPY --from=downloader C:\eventstore\EventStore-OSS-Windows-2019-v20.10.0 .
COPY eventstore.conf .\Config\

# Run Service
SHELL ["cmd", "/S", "/C"]
CMD "C:\eventstore\EventStore.ClusterNode.exe --db /Data --log /Logs --config=C:\eventstore\Config\eventstore.conf"
