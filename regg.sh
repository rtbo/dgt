#! /bin/bash

while getopts "cbrt:a:d:" opt; do
    case $opt in
      c) config=1 ;;
      b) build=1 ;;
      r) run=1 ;;
      t) buildType=$OPTARG ;;
      a) arch=$OPTARG ;;
      d) dc=$OPTARG ;;
    esac
done

shift $((OPTIND - 1))
if [ $# -ne 0 ] ; then
    target=$1
    shift
fi

if [[ -z $config ]] && [[ -n $buildType ]] ; then
    echo -e buildType only useful with config
    exit 1
fi
if [[ -z $config ]] && [[ -n $arch ]] ; then
    echo -e arch only useful with config
    exit 1
fi
if [[ -z $config ]] && [[ -n $dc ]] ; then
    echo -e dc only useful with config
    exit 1
fi
if [[ -n $run ]] && [[ -z $target ]] ; then
    echo -e run only makes sense with a target
    exit 1
fi

if [[ -n $target ]] ; then
    case $target in
        hello)
            target_dir=examples/hello
            target_exe=examples/hello/hello
            ;;
        proverbs)
            target_dir=examples/proverbs
            target_exe=examples/proverbs/proverbs
            ;;
        *)
            echo -e unknown target $target
            exit 1
            ;;
    esac
fi

if [[ -n $config ]] ; then
    echo configuring $target
    reggae_args=( -b ninja )
    if [[ -n $buildType ]] ; then
        # no builtin build type in reggae (?)
        # specifying through script vars
        reggae_args+=( -d buildType=$buildType )
    fi
    if [[ -n $arch ]] ; then
        reggae_args+=( --dub-arch $arch )
    fi
    if [[ -n $dc ]] ; then
        reggae_args+=( --dc $dc )
    fi
    if [[ -n $target_dir ]] ; then
        reggae_args+=( $target_dir -C $target_dir )
    fi
    echo calling reggae "${reggae_args[@]}"
    reggae "${reggae_args[@]}"
fi

if [[ -n $build ]] ; then
    echo building $target
    ninja_args=()
    if [[ -n $target_dir ]] ; then
        ninja_args+=( -C $target_dir )
    fi
    if ninja "${ninja_args[@]}" && [[ -z $target ]] ; then
        cp dgt libdgt.a
    fi
fi

if [[ -n $run ]] ; then
    echo running $target
    while [ $# -ne 0 ] ; do
        $arg = $1
        shift
        if [[ "$arg" = "--" ]] ; then
            break
        fi
    done
    "$target_exe" "$@"
fi
