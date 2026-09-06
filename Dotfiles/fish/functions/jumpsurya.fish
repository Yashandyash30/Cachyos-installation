function jumpsurya --description 'Jump to Surya HPC terminal'
    set target_dir (_get_surya_target_dir $argv[1])
    echo "Jumping to Surya HPC at $target_dir..."
    ssh -t yashsharma@192.168.4.1 "cd '$target_dir' && exec bash --noprofile --rcfile ~/.bashrc"
end
