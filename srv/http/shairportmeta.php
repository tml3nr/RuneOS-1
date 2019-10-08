#!/usr/bin/php

<?php
$code = '';
while ( 1 ) {
	$lines = file_get_contents( '/tmp/shairport-sync-metadata' );
	$line = strtok( $lines, "\n" );
	
	while ( $line ) {
		if ( strpos( $line, '61736172' ) ) {
			$code = 'Artist';
		} else if ( strpos( $line, '6d696e6d' ) ) {
			$code = 'Title';
		} else if ( strpos( $line, '6173616c' ) ) {
			$code = 'Album';
		} else if ( strpos( $line, '50494354' ) ) {
			$code = 'coverart';
		}
		if ( $code && strpos( $line, '</data></item>' ) ) {
			$data = str_replace( '</data></item>', '', $line );
			if ( $code === 'coverart' ) {
				file_put_contents( '/srv/http/data/tmp/airplaycoverart', "data:image/jpeg;base64,$data" );
			} else {
				file_put_contents( "/srv/http/data/tmp/airplay$code", base64_decode( $data ) );
				if ( $code === 'Title' ) exec( "/usr/bin/sudo /usr/bin/curl -s -X POST 'http://localhost/pub?id=airplay' -d 2" );
			}
			$code = '';
		}
		
		$line = strtok( "\n" ); //////////
	}
}
