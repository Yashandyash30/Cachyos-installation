function mesaz --description 'Attach or create persistent Zellij session for MESA on remote server'
    set server $argv[1]
    set session_name $argv[2]

    if test -z "$server"
        echo "Usage: mesaz <aries|surya> [session_name]"
        return 1
    end

    if test -z "$session_name"
        set session_name "mesa_$server"
    end

    switch $server
        case aries
            set target_host "shashi@172.18.1.5"
        case surya
            set target_host "yashsharma@192.168.4.1"
        case '*'
            set target_host $server
    end

    echo "Jumping into persistent Zellij session '$session_name' on $server..."
    ssh -t $target_host "exec bash --noprofile --rcfile ~/.bashrc -i -c 'zellij attach -c $session_name'"
end
