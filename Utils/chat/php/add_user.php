﻿<?php
    include "clean_users.php";

    echo "Add user";
    $mysqli = new mysqli("localhost", "assoft_user", "assoft_user0", "assoft");
    
     if($stmt = $mysqli ->prepare("CALL add_user(?, ?, ?)"))
     {
        $u1 = $_POST['name'];
        $u2 = $_POST['password'];
        $u3 = $_POST['ip'];
        $stmt->bind_param('sss', $u1, $u2, $u3);
        if (!$stmt->execute())
        {
          echo "  fail:   ";
          echo $mysqli->error;
          echo '<br>ErrorCode = '.$mysqli->errno; 
        }
        $stmt->close();    
     }
     else
     {
        echo $mysqli ->error;
     }
    
    $mysqli->close(); 
?>