function mesagui --description 'Launch remote MESA session with live PGSTAR GUI forwarding'
    set server $argv[1]
    set version $argv[2]
    set work_dir $argv[3]

    if test -z "$server"
        echo "Usage: mesagui <aries|surya> [23|26] [work_directory]"
        return 1
    end

    if test -z "$version"
        set version 23
    end

    switch $server
        case aries
            set target_host "shashi@172.18.1.5"
        case surya
            set target_host "yashsharma@192.168.4.1"
        case '*'
            set target_host $server
    end

    set cmd "mesa$version"
    if test -n "$work_dir"
        set cmd "cd '$work_dir' && mesa$version"
    end

    echo "Connecting to $server with Trusted X11 Forwarding for MESA $version..."
    ssh -Y -t $target_host "exec bash --noprofile --rcfile ~/.bashrc -i -c '$cmd'"
end
