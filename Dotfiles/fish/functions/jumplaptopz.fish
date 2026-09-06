function jumplaptopz
    set target_dir (_get_laptop_target_dir)
    
    echo "Jumping to Zellij session on Laptop at $target_dir..."
    ssh -t void@100.70.236.70 "cd '$target_dir' && exec zellij attach -c astro_laptop"
end
