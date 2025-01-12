#!/bin/bash

# Check if a path was provided as an argument
if [ -z "$1" ]; then
    echo "Please provide a path to the directory with images."
    exit 1
fi

# Path to the directory with images
dir="$1"

# Check if the directory exists
if [ ! -d "$dir" ]; then
    echo "Directory $dir does not exist."
    exit 1
fi

# Create output directory if it does not exist
output_dir="$dir/output"
mkdir -p "$output_dir"

# Dimensions for 10x15 cm at 1200 dpi (4724x7086 px)
width=4800
height=7200
tolerance=0.02

# Iterate over all jpg files in the directory
for file in "$dir"/*.jpg; do
    # Check if the file exists
    if [ -f "$file" ]; then
        # Get image dimensions
        original_width=$(identify -format "%w" "$file")
        original_height=$(identify -format "%h" "$file")

        # Calculate aspect ratio
        aspect_ratio=$(echo "scale=2; $original_width / $original_height" | bc)

        # Check if the aspect ratio is 3:2 or 2:3
        if [[ $(echo "$aspect_ratio > 1.50 - $tolerance && $aspect_ratio < 1.50 + $tolerance" | bc -l) -eq 1 || 
              $(echo "$aspect_ratio > 0.67 - $tolerance && $aspect_ratio < 0.67 + $tolerance" | bc -l) -eq 1 ]]; then
            # Get the date from EXIF metadata
            d=$(exiftool -T -DateTimeOriginal -d "%Y.%m.%d %H:%M" "$file")

            # Check if the date was retrieved
            if [ -z "$d" ] || [[ "$d" == *"-"* ]]; then
                echo "Date not found for file $file"
                continue
            fi

            # Check the orientation of the image
            if [ "$original_width" -gt "$original_height" ]; then
                # Landscape photo
                resize_dims="${height}x${width}"  # Target size for landscape
                xannotate=150
                yannotate=260
            else
                # Portrait photo
                resize_dims="${width}x${height}"  # Target size for portrait
                xannotate=120
                yannotate=100
            fi

            # Add date to the image, changing resolution and size
            convert "$file" -density 1200 -resize "$resize_dims" -background transparent \
              -font "Courier-Bold" -pointsize 5 -fill black -gravity southeast \
              -annotate "+$(($xannotate + 1))+$(($yannotate + 1))" "$d" \
              -annotate "+$(($xannotate + 1))+$(($yannotate - 1))" "$d" \
              -annotate "+$(($xannotate - 1))+$(($yannotate + 1))" "$d" \
              -annotate "+$(($xannotate - 1))+$(($yannotate - 1))" "$d" \
              -fill orange -gravity southeast -annotate "+${xannotate}+${yannotate}" "$d" "$output_dir/$(basename "$file")"

            echo "Processed $file"
        else
            echo "Skipped $file (aspect ratio is not 3:2 or 2:3) - $aspect_ratio"
        fi
    fi
done

echo "Image processing completed."
