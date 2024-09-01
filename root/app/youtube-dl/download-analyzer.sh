#!/usr/bin/with-contenv bash

# Caminho do arquivo channels.txt
channels_file="/config/channels.txt"
# Caminho da pasta onde o channels.txt está localizado
base_dir=$(dirname "$channels_file")
# Arquivos de saída
download_archive="$base_dir/download-archive.txt"
failed_videos="$base_dir/failed-videos.txt"

# Cria os arquivos se ainda não existirem
touch "$download_archive"
touch "$failed_videos"

# Converte arquivos de saída em listas para verificação mais rápida
downloaded_links=$(cat "$download_archive")
failed_links=$(cat "$failed_videos")

# Loop através de cada URL em channels.txt
while IFS= read -r url
do
  # Expande o link do canal do YouTube em todos os links de vídeo
  yt-dlp --flat-playlist --get-id --get-title --get-url "$url" | while IFS= read -r video_url
  do
    # Verifica se o link já está em uma das listas
    if grep -Fxq "$video_url" <<< "$downloaded_links"; then
      echo "Link já está no download-archive.txt, pulando: $video_url"
      continue
    elif grep -Fxq "$video_url" <<< "$failed_links"; then
      echo "Link já está no failed-videos.txt, pulando: $video_url"
      continue
    fi

    # Verifica se o vídeo pode ser baixado ou se há algum bloqueio/erro
    if yt-dlp --simulate --no-warnings --quiet "$video_url" > /dev/null 2>&1; then
      # Se o vídeo pode ser completado, grava o link no download-archive.txt
      echo "$video_url" >> "$download_archive"
    else
      # Se houver erro, grava o link no failed-videos.txt
      echo "$video_url" >> "$failed_videos"
    fi
  done
done < "$channels_file"

echo "Verificação completa. Resultados salvos em:"
echo " - $download_archive"
echo " - $failed_videos"
