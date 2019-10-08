<?php
$artist = $_POST[ 'artist' ];
$song = $_POST[ 'song' ];
$filelyrics = '/srv/http/data/lyrics/'.strtolower( $artist.' - '.$song ).'.txt';

if ( isset( $_POST[ 'delete' ] ) ) {
	echo unlink( $filelyrics );
} else {
	echo file_put_contents( $filelyrics, $_POST[ 'lyrics' ] );
}
