function jumparies --description 'Jump to ARIES server terminal'
    set target_dir (_get_aries_target_dir $argv[1])
    echo "Jumping to ARIES server at $target_dir..."
    ssh -t shashi@172.18.1.5 "cd '$target_dir' && exec bash --noprofile --rcfile ~/.bashrc"
end
