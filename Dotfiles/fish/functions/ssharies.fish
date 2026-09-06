function ssharies --description 'SSH into ARIES server (instant clean login)'
    if test (count $argv) -eq 0
        ssh -t shashi@172.18.1.5 "exec bash --noprofile --rcfile ~/.bashrc"
    else
        ssh shashi@172.18.1.5 $argv
    end
end
