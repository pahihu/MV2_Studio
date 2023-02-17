input_png=MV2_Studio.png
output_path=./MV2_Studio.iconset

rm -f MV2_Studio.icns
rm -rf $output_path
mkdir $output_path

# the convert command comes from imagemagick
for size in 16 32 64 128 256; do
  half="$(($size / 2))"
  sips -z $size $size $input_png --out $output_path/icon_${size}x${size}.png
  sips -z $size $size $input_png --out $output_path/icon_${half}x${half}@2x.png
done

iconutil -c icns $output_path

rm -rf $output_path

cp MV2_Studio.icns ..
