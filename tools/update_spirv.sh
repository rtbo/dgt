#! /bin/sh

TOOLS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DGT_DIR="$( dirname ${TOOLS_DIR} )"
VIEWS_DIR=$DGT_DIR/source/dgt/render/views
SHADERS_DIR=$DGT_DIR/source/dgt/render/shaders

function gen_spirv() {
    glsl=$1
    spirv=$2

    if [ ! -f "$spirv" ] || [ "$spirv" -ot "$glsl" ]; then
        echo "Generating $spirv"
        glslangValidator -V $glsl -o $spirv || exit 1

    else
        echo "$spirv is up-to-date"
    fi
}

for glsl in {$SHADERS_DIR/*.vert,$SHADERS_DIR/*.frag}; do
    gen_spirv $glsl $VIEWS_DIR/${glsl##*/}.spv
done
