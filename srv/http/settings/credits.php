<?php
$list05 = array(
	  'Gearhead' => [ 'https://github.com/gearhead', 'RuneOS - Full kernel and package upgrade, kernel patch for alsa 384kHz audio support and Chromium local browser' ]
	, 'janui'    => [ 'https://github.com/janui', 'RuneUI - Shairport sync with metadata, random play and autostart rework, Samba optimisation and 101 bugfixes' ]
);
$list04 = array(
	 'Frank Friedmann' => [ 'https://github.com/hondagx35', 'A grand solo effort, AP, Local Browser, Lyrics, many upgrades, bugfixes and other improvements', 'hondagx35' ]
);
$list0103 = array(
	  'Andrea Coiutti'        => [ 'http://www.runeaudio.com/team/', 'RuneUI frontend design - frontend HTML/JS/CSS coding', 'ACX' ]
	, 'Simone De Gregori'     => [ 'http://www.runeaudio.com/team/', 'RuneUI PHP backend coding - frontend JS coding - RuneOS distro build &amp; optimization', 'Orion' ]
	, 'Carmelo San Giovanni'  => [ 'http://www.runeaudio.com/team/', 'RuneOS distro build &amp; Kernel optimization', 'Um3ggh1U' ]
	, 'Cristian Pascottini'   => [ 'https://github.com/cristianp6', 'RuneUI Javascript optimizations' ]
	, 'Valerio Battaglia'     => [ 'https://github.com/vabatta', 'RuneUI Javascript optimizations' ]
	, 'Frank Friedmann'       => [ 'https://github.com/hondagx35', 'RuneUI/RuneOS PHP backend code debug, refactoring of network management, RuneOS porting for Cubietruck', 'hondagx35' ]
	, 'Kevin Welsh'           => [ 'https://github.com/kdubious', 'RuneUI/RuneOS Frontend & backend development', 'kdubious' ] 
	, 'Andrea Rizzato'        => [ 'https://github.com/GitAndrer', 'RuneUI/RuneOS PHP backend code debug, integration of Wolfson Audio Card', 'AandreR' ]
	, 'Saman'                 => [ 'http://www.runeaudio.com/forum/member275.html', 'RuneOS RT Linux kernel for Wolfson Audio Card (RaspberryPi)' ]
	, 'Daniele Scasciafratte' => [ 'https://github.com/Mte90', 'RuneUI Firefox integration', 'Mte90' ]
	, 'Francesco Casarsa'     => [ 'https://github.com/fcasarsa', 'Shairport patch', 'CAS' ]
);
$list05html = '';
foreach( $list05 as $name => $value ) {
	$list05html.= '<a href="'.$value[ 0 ].'" target="_blank">'.$name.'</a><br><span class="help-block hide">'.$value[ 1 ].'<br></span>';
}
$list04html = '';
foreach( $list04 as $name => $value ) {
	$list04html.= '<a href="'.$value[ 0 ].'" target="_blank">'.$name.' <gr>(aka '.$value[ 2 ].')</gr></a><span class="help-block hide">'.$value[ 1 ].'</span><br>';
}
$list0103html = '';
foreach( $list0103 as $name => $value ) {
	$aka = isset( $value[ 2 ] ) ? ' <gr>(aka '.$value[ 2 ].')</gr>' : '';
	$list0103html.= '<a href="'.$value[ 0 ].'" target="_blank">'.$name.$aka.'</a><br><span class="help-block hide">'.$value[ 1 ].'<br></span>';
}
$listruneui = array(
	  'HTML5-Color-Picker'  => 'https://github.com/NC22/HTML5-Color-Picker'
	, 'jQuery'              => 'https://jquery.com/'
	, 'jQuery.documentSize' => 'https://github.com/hashchange/jquery.documentsize'
	, 'jQuery Mobile'       => 'https://jquerymobile.com/'
	, 'jquery.qrcode.js'    => 'https://github.com/jeromeetienne/jquery-qrcode'
	, 'jQuery Selectric'    => 'https://github.com/lcdsantos/jQuery-Selectric'
	, 'Lato-Fonts'          => 'http://www.latofonts.com/lato-free-fonts'
	, 'LazyLoad'            => 'https://github.com/verlok/lazyload'
	, 'pica'                => 'https://github.com/nodeca/pica'
	, 'roundSlider'         => 'https://github.com/soundar24/roundSlider'
	, 'Sortable'            => 'https://github.com/SortableJS/Sortable'
);
$runeuihtml = '';
foreach( $listruneui as $name => $link ) {
	$runeuihtml.= '<a href="'.$link.'">'.$name.'</a><br>';
}
$listruneos = array(
	  'Alac'                     => 'https://github.com/TimothyGu/alac'
	, 'ArchLinuxArm'             => 'https://www.archlinuxarm.org'
	, 'BlueZ'                    => 'http://www.bluez.org'
	, 'BlueZ-Alsa'               => 'https://github.com/Arkq/bluez-alsa'
	, 'BlueZ-Utils-Compat'       => 'href="https://aur.archlinux.org/packages/bluez-utils-compat'
	, 'FFmpeg'                   => 'http://ffmpeg.org'
	, 'Hfsprogs'                 => 'http://www.opensource.apple.com'
	, 'Hfsutils'                 => 'http://www.opensource.apple.com'
	, 'ImageMagick'              => 'https://imagemagick.org/'
	, 'Kid3 - Audio Tagger'      => 'https://kid3.sourceforge.io/'
	, 'MPD'                      => 'http://www.musicpd.org/'
	, 'NGINX'                    => 'http://nginx.org'
	, 'NGINX Push Stream Module' => 'https://github.com/wandenberg/nginx-push-stream-module'
	, 'PHP'                      => 'http://php.net'
	, 'Pi-Bluetooth'             => 'https://aur.archlinux.org/pi-bluetooth.git'
	, 'raspi-rotate'             => 'https://github.com/colinleroy/raspi-rotate'
	, 'Samba'                    => 'http://www.samba.org'
	, 'Shairport-sync'           => 'https://github.com/mikebrady/shairport-sync'
	, 'upmpdcli'                 => 'http://www.lesbonscomptes.com/upmpdcli/'
);
$runeoshtml = '';
foreach( $listruneos as $name => $link ) {
	$runeoshtml.= '<a href="'.$link.'">'.$name.'</a><br>';
}
?>
<div class="container credits">
	<h1>RuneAudio</h1>
	<heading><i class="fa fa-addons gr"></i> <?=( file_get_contents( '/srv/http/data/system/version' ) )?></heading>
	<a href="https://github.com/rern/">r e r n</a><br>
	<span class="help-block hide">
		System-wide upgraded.<br>
		Integrated addons:
		<p class="indent gr">
		- Addons<br>
		- RuneUI Enhancement<br>
		- RuneUI Lyrics<br>
		- RuneUI Metadata Tag Editor<br>
		- USB DAC Hotplug</p>
	</span>
	<heading>Version 0.5</heading>
	<?=$list05html?>
	<heading>Version 0.4</heading>
	<?=$list04html?>
	<heading>Version 0.1 - 0.3</heading>
	<?=$list0103html?>
	<heading>Support us</heading>
	<form id="form-paypal" action="https://www.paypal.com/cgi-bin/webscr" method="post" target="_top">
		<input type="hidden" name="cmd" value="_s-xclick">
		<input type="hidden" name="hosted_button_id" value="AZ5L5M5PGHJNJ">
		<input type="image" src="/assets/img/donate.png" name="submit" style="height: 55px">
	</form>
	<heading>License &amp; Copyright</heading>
		<gr>This Program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation either version 3, 
		or (at your option) any later version. This Program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
		See the GNU General Public License for more details. You should have received a copy of the GNU General Public License along with RuneAudio; see the file COPYING. 
		If not, see <a href="http://www.gnu.org/licenses/gpl-3.0.txt" target="_blank" rel="nofollow">http://www.gnu.org/licenses/gpl-3.0.txt</a></gr>
	<p>
		Copyright (C) 2013-2014 RuneAudio Team
		<br><gr>Andrea Coiutti &amp; Simone De Gregori &amp; Carmelo San Giovanni</gr><br>
		RuneUI
		<br><gr>copyright (C) 2013-2014 – Andrea Coiutti (aka ACX) &amp; Simone De Gregori (aka Orion)</gr><br>
		RuneOS
		<br><gr>copyright (C) 2013-2014 – Simone De Gregori (aka Orion) &amp; Carmelo San Giovanni (aka Um3ggh1U)</gr>
	</p>
	<heading>RuneUI</heading>
	<?=$runeuihtml?>
	<br>
	<heading>RuneOS</heading>
	<?=$runeoshtml?>
	<div style="clear: both"></div>
</div>
