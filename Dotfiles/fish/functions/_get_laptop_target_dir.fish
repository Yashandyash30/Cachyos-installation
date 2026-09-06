function _get_laptop_target_dir
    if string match -q "/mnt/Laptop_Home*" $PWD
        set target_dir (string replace "/mnt/Laptop_Home" "/home/void" $PWD)
    else if string match -q "/mnt/Storage*" $PWD
        set target_dir (string replace "/mnt/Storage" "/mnt/PC_Storage" $PWD)
    else if string match -q "/home/void*" $PWD
        set target_dir (string replace "/home/void" "/mnt/PC_Home" $PWD)
    else
        set target_dir "/home/void"
    end
    
    echo $target_dir
end
