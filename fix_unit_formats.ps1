foreach ($x in dir C:\Users\Ideapad\Desktop\test -Recurse | where {$_.extension -eq ".zip"}) {

    $filename = $x.fullname
    $pathname = $x.directory.fullname
    $foldername = $x.directory.name
    $7z = "C:\Program Files\7-Zip\7z.exe"
    
    function unzip_stuff {

        & $7z x $filename "-o$pathname"
 
    }

    function modify_file {
     
        foreach ($k in dir $pathname -Recurse | where {$_.extension -ne ".zip" -and $_.Attributes -ne "Directory"}) {
            "hello sveta" | Out-File $k.fullname
        }
        
    }
    
    function delete_old_zip {
    
        if (test-path $x.fullname) {
    	del $x.fullname
        }
    
    }
    
    function create_new_zip {
    
    & $7z a -tzip "$pathname\$foldername.zip" "$pathname\*"    
   
    }
    
    function delete_old_files {

        Remove-Item $pathname\* -recurse -exclude *.zip
    
    }
    
    function run_functions {
    unzip_stuff
    modify_file
    delete_old_zip
    create_new_zip
    delete_old_files
    }
    run_functions
  
}
