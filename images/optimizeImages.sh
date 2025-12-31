#!/bin/bash

# Image optimization script for web
# Converts JPG images to WebP format with optimization

# Configuration
INPUT_DIR="./raw"
OUTPUT_DIR="./optimized"
MAX_WIDTH=870
MAX_HEIGHT=870
WEBP_QUALITY=82  # WebP at 82 ≈ JPG at 85-90

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== WebP Image Optimization Script ===${NC}"
echo ""

# Check if ImageMagick is installed
if ! command -v convert &> /dev/null; then
    echo -e "${RED}Error: ImageMagick is not installed${NC}"
    echo "Install it with: sudo apt install imagemagick"
    exit 1
fi

# Check WebP support
if ! convert -list format | grep -q WEBP; then
    echo -e "${YELLOW}Warning: WebP support not detected in ImageMagick${NC}"
    echo "You may need to install: sudo apt install webp libwebp-dev"
    echo ""
fi

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Check if input directory exists
if [ ! -d "$INPUT_DIR" ]; then
    echo -e "${RED}Error: Input directory '$INPUT_DIR' does not exist${NC}"
    echo "Please create it and place your images there"
    exit 1
fi

# Count images
IMAGE_COUNT=$(find "$INPUT_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" \) | wc -l)

if [ "$IMAGE_COUNT" -eq 0 ]; then
    echo -e "${RED}No JPG images found in $INPUT_DIR${NC}"
    exit 1
fi

echo -e "Found ${GREEN}$IMAGE_COUNT${NC} images to process"
echo -e "Max dimensions: ${MAX_WIDTH}x${MAX_HEIGHT}px"
echo -e "WebP Quality: ${WEBP_QUALITY}%"
echo ""

# Process images
COUNTER=0
TOTAL_ORIGINAL_SIZE=0
TOTAL_OPTIMIZED_SIZE=0

find "$INPUT_DIR" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" \) | while read -r img; do
    
    COUNTER=$((COUNTER + 1))
    FILENAME=$(basename "$img")
    FILENAME_NO_EXT="${FILENAME%.*}"
    OUTPUT_PATH="$OUTPUT_DIR/${FILENAME_NO_EXT}.webp"
    
    # Get original size
    ORIGINAL_SIZE=$(stat -f%z "$img" 2>/dev/null || stat -c%s "$img" 2>/dev/null)
    TOTAL_ORIGINAL_SIZE=$((TOTAL_ORIGINAL_SIZE + ORIGINAL_SIZE))
    
    echo -e "${BLUE}[$COUNTER/$IMAGE_COUNT]${NC} Processing: $FILENAME → ${FILENAME_NO_EXT}.webp"
    
    # Resize and convert to WebP
    convert "$img" \
        -resize "${MAX_WIDTH}x${MAX_HEIGHT}>" \
        -strip \
        -quality "$WEBP_QUALITY" \
        -define webp:method=6 \
        -define webp:alpha-quality=100 \
        "$OUTPUT_PATH"
    
    # Get optimized size
    OPTIMIZED_SIZE=$(stat -f%z "$OUTPUT_PATH" 2>/dev/null || stat -c%s "$OUTPUT_PATH" 2>/dev/null)
    TOTAL_OPTIMIZED_SIZE=$((TOTAL_OPTIMIZED_SIZE + OPTIMIZED_SIZE))
    
    # Calculate reduction
    REDUCTION=$(awk "BEGIN {printf \"%.1f\", (1 - $OPTIMIZED_SIZE / $ORIGINAL_SIZE) * 100}")
    
    echo -e "  Original JPG: $(numfmt --to=iec-i --suffix=B $ORIGINAL_SIZE) → WebP: $(numfmt --to=iec-i --suffix=B $OPTIMIZED_SIZE) (${GREEN}-${REDUCTION}%${NC})"
    echo ""
done < <(find "$INPUT_DIR" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" \))

# Summary
echo -e "${GREEN}=== Optimization Complete ===${NC}"
echo -e "Total images processed: $COUNTER"
echo -e "Total original size: $(numfmt --to=iec-i --suffix=B $TOTAL_ORIGINAL_SIZE)"
echo -e "Total optimized size: $(numfmt --to=iec-i --suffix=B $TOTAL_OPTIMIZED_SIZE)"

if [ "$TOTAL_ORIGINAL_SIZE" -gt 0 ]; then
    TOTAL_REDUCTION=$(awk "BEGIN {printf \"%.1f\", (1 - $TOTAL_OPTIMIZED_SIZE / $TOTAL_ORIGINAL_SIZE) * 100}")
    echo -e "Total space saved: ${GREEN}${TOTAL_REDUCTION}%${NC}"
fi

echo ""
echo -e "Optimized images saved to: ${BLUE}$OUTPUT_DIR${NC}"
echo -e "${YELLOW}Tip: Use <picture> element with WebP for best browser support${NC}"
