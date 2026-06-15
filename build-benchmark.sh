#!/bin/bash

# Build script for performance benchmarking
# Generates JIT and AOT builds for comparison

set -e

echo "================================================"
echo "MBAAPI Build Script - JIT and AOT Compilation"
echo "================================================"
echo ""

OUTPUT_DIR="./build-output"
mkdir -p "$OUTPUT_DIR"

# Build JIT Release
echo "[1/4] Building JIT Release..."
dotnet build -c Release -o "$OUTPUT_DIR/jit-release" --no-incremental
echo "✓ JIT Release build completed"
echo ""

# Publish JIT Release
echo "[2/4] Publishing JIT Release..."
dotnet publish -c Release -o "$OUTPUT_DIR/jit-publish" --no-build --no-restore
echo "✓ JIT Release publish completed"
echo ""

# Build AOT Release
echo "[3/4] Building ReleaseAOT..."
dotnet build -c ReleaseAOT -o "$OUTPUT_DIR/aot-release" --no-incremental
echo "✓ AOT Release build completed"
echo ""

# Publish AOT Release
echo "[4/4] Publishing ReleaseAOT..."
dotnet publish -c ReleaseAOT -o "$OUTPUT_DIR/aot-publish" --no-build --no-restore
echo "✓ AOT Release publish completed"
echo ""

echo "================================================"
echo "Build Summary:"
echo ""

# Display sizes
JIT_SIZE=$(du -sh "$OUTPUT_DIR/jit-publish" | cut -f1)
AOT_SIZE=$(du -sh "$OUTPUT_DIR/aot-publish" | cut -f1)

echo "JIT Publish Size: $JIT_SIZE"
echo "AOT Publish Size: $AOT_SIZE"
echo ""
echo "Output directories:"
echo "  - JIT Release:  $OUTPUT_DIR/jit-release"
echo "  - JIT Publish:  $OUTPUT_DIR/jit-publish"
echo "  - AOT Release:  $OUTPUT_DIR/aot-release"
echo "  - AOT Publish:  $OUTPUT_DIR/aot-publish"
echo ""
