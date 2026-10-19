# Run from the Flutter project root. Data is only for screenshots, never the app.
$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Force tool/capture_data/images | Out-Null
Invoke-WebRequest -Uri 'https://api.tvmaze.com/shows?page=0' -OutFile 'tool/capture_data/catalogue.json' -TimeoutSec 30
Invoke-WebRequest -Uri 'https://api.tvmaze.com/search/shows?q=breaking' -OutFile 'tool/capture_data/search.json' -TimeoutSec 30
$results = Get-Content tool/capture_data/search.json -Raw | ConvertFrom-Json
$showId = ($results | Where-Object { $_.show.name -eq 'Breaking Bad' } | Select-Object -First 1).show.id
foreach ($section in @('details', 'cast', 'episodes')) {
  $endpoint = if ($section -eq 'details') { "https://api.tvmaze.com/shows/$showId" } else { "https://api.tvmaze.com/shows/$showId/$section" }
  Invoke-WebRequest -Uri $endpoint -OutFile "tool/capture_data/$section.json" -TimeoutSec 30
}
$catalogue = Get-Content tool/capture_data/catalogue.json -Raw | ConvertFrom-Json
$urls = @($catalogue | Select-Object -First 12 | ForEach-Object { $_.image.medium }) + @($results | ForEach-Object { $_.show.image.medium })
foreach ($url in ($urls | Where-Object { $_ } | Select-Object -Unique)) {
  $filename = ([Uri]$url).Segments[-1]
  Invoke-WebRequest -Uri $url -OutFile "tool/capture_data/images/$filename" -TimeoutSec 30
}
$flutterCommand = (Get-Command flutter).Source
$flutterRoot = Split-Path (Split-Path $flutterCommand -Parent) -Parent
Copy-Item "$flutterRoot/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf" tool/capture_data/Roboto-Regular.ttf
Copy-Item "$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf" tool/capture_data/MaterialIcons-Regular.otf
$cast = Get-Content tool/capture_data/cast.json -Raw | ConvertFrom-Json
foreach ($url in ($cast | Select-Object -First 10 | ForEach-Object { $_.person.image.medium } | Where-Object { $_ } | Select-Object -Unique)) {
  $filename = ([Uri]$url).Segments[-1]
  Invoke-WebRequest -Uri $url -OutFile "tool/capture_data/images/$filename" -TimeoutSec 30
}
