<?php
echo 'hi';
flush();
sleep(5);
echo 'hi2';
flush();
sleep(5);
die('meh');

