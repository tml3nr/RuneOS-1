<?php
$hostname = getData( 'hostname' );
$audiooutput = getData( 'audiooutput' );
$i2ssysname = getData( 'i2ssysname' );
$soundprofile = getData( 'soundprofile' ) === 'default';
$password = getData( 'login' ) ? 'checked' : '';
$passworddefault = password_verify( 'rune', getData( 'password' ) ) ? ' data-default="1"' : '';
$version = getData( 'version' );

$data = json_decode( shell_exec( '/srv/http/settings/systemdata.sh' ) );

date_default_timezone_set( $data->timezone );
$timezonelist = timezone_identifiers_list();
$optiontimezone = '';
foreach( $timezonelist as $key => $zone ) {
	$selected = $zone === $data->timezone ? ' selected' : '';
	$datetime = new DateTime( 'now', new DateTimeZone( $zone ) );
	$offset = $datetime->format( 'P' );
	$zonename = preg_replace( array( '/_/', '/\//' ), array( ' ', ' <gr>&middot;</gr> ' ), $zone );
	if ( $selected ) $zonestring = $data->timezone === 'UTC' ? 'UTC' : explode( ' <gr>&middot;</gr> ', $zonename, 2 )[ 1 ];
	$optiontimezone.= '<option value="'.$zone.'"'.$selected.'>'.$zonename.'&ensp;'.$offset."</option>\n";
}

// set value
//   - append '/boot/config.txt' with 'dtoverlay' file names in '/boot/overlays/*'
//   - set value to /srv/http/data/system/audiooutput
//   - disable on-board audio in '/boot/config.txt'
//   - reboot
//   - '/srv/http/settings/mpdconf.sh' - parse sysnames with 'aplay -l' and populate to '/etc/mpd.conf'
//
//   - MPD setting page - get names from '/srv/http/settings/i2s/*' or 'mpc outputs'
//   - set selected to audiooutput value
include '/srv/http/settings/system_i2smodules.php';
$optioni2smodule = '';
foreach( $i2slist as $name => $sysname ) {
	$selected = ( $name === $audiooutput && $sysname === $i2ssysname ) ? ' selected' : '';
	$optioni2smodule.= "<option value=\"$sysname\"$selected>$name</option>";
}
?>
<div class="container">
	<heading>System Status</heading>
		<div class="col-l text gr">
			RuneAudio<br>
			Kernel<br>
			Hardware<br>
			Time<br>
			Up time<br>
			Since
		</div>
		<div class="col-r text">
			<i class="fa fa-addons gr"></i> <?=$version?><br>
			<?=$data->kernel?><br>
			<?=$data->hardware?><br>
			<?=$data->date?><gr>&emsp;@ </gr><?=$zonestring?><br>
			<?=$data->uptime?><br>
			<?=$data->since?>
		</div>
	<heading>Environment</heading>
		<div class="col-l">Player name</div>
		<div class="col-r">
			<input type="text" id="hostname" value="<?=$hostname?>" readonly style="cursor: pointer">
			<span class="help-block hide">Set the player hostname. This will change the address used to reach the RuneUI. Local access point, AirPlay, Samba and UPnP/upnp will broadcast this name when enabled.<br>
			(No spaces or special charecters allowed in the name.)</span>
		</div>
		<div class="col-l">Timezone</div>
		<div class="col-r">
			<select id="timezone" data-style="btn-default btn-lg">
				<?=$optiontimezone?>
			</select>
			<i id="setting-ntp" data-ntp="<?=$data->ntp?>" class="settingedit fa fa-gear"></i><br>
			<span class="help-block hide">Network Time Protocol server.</span></span>
		</div>
	<heading>Audio</heading>
		<div class="col-l">I&#178;S Module</div>
		<div class="col-r i2s">
			<div id="divi2smodulesw"<?=( $i2ssysname ? ' class="hide"' : '' )?>>
				<input id="i2smodulesw" type="checkbox">
				<div class="switchlabel" for="i2smodulesw"></div>
			</div>
			<div id="divi2smodule"<?=( $i2ssysname ? '' : ' class="hide"' )?>>
				<select id="i2smodule" data-style="btn-default btn-lg">
					<?=$optioni2smodule?>
				</select>
			</div>
			<span class="help-block hide">I&#178;S modules are not plug-and-play capable. Select a driver for installed device.</span>
		</div>
		<div class="col-l">Sound Profile</div>
		<div class="col-r">
			<input id="soundprofile" type="checkbox" value="<?=$soundprofile?>"<?=( $soundprofile ? '' : ' checked' )?>>
			<div class="switchlabel" for="soundprofile"></div>
			<i id="setting-soundprofile" class="setting fa fa-gear<?=( $soundprofile ? ' hide' : '' )?>"></i>
			<span class="help-block hide">System kernel parameters tweak: eth0 mtu, eth0 txqueuelen, swappiness and sched_latency_ns.</span>
		</div>
	<heading>On-board devices</heading>
		<div id="divonboardaudio"<?=( $i2ssysname ? '' : ' class="hide"' )?>>
			<div class="col-l">Audio</div>
			<div class="col-r">
				<input id="onboardaudio" type="checkbox" <?=$data->onboardaudio?>>
				<div class="switchlabel" for="onboardaudio"></div>
				<span class="help-block hide">3.5mm phone and HDMI outputs.</span>
			</div>
		</div>
		<div class="col-l">Bluetooth</div>
		<div class="col-r">
			<input id="bluetooth" type="checkbox" <?=$data->bluetooth?>>
			<div class="switchlabel" for="bluetooth"></div>
			<span class="help-block hide">Should be disabled if not used.</span>
		</div>
		<div class="col-l">Wi-Fi</div>
		<div class="col-r">
			<input id="wlan" type="checkbox" <?=$data->wlan?>>
			<div class="switchlabel" for="wlan"></div>
			<span class="help-block hide">Should be disabled if not used.</span>
		</div>
	<heading>Features</heading>
		<div class="col-l gr">AirPlay<i class="fa fa-airplay fa-lg wh"></i></div>
		<div class="col-r">
			<input id="airplay" type="checkbox" <?=$data->airplay?>>
			<div class="switchlabel" for="airplay"></div>
			<span class="help-block hide"><wh>Shairport Sync</wh> - Receive audio streaming via AirPlay protocol.</span>
		</div>
		<div class="col-l gr">Browser on RPi<i class="fa fa-chromium fa-lg wh"></i></div>
		<div class="col-r">
			<input id="localbrowser" type="checkbox" data-cursor="<?=$data->cursor?>" data-overscan="<?=$data->overscan?>" data-rotate="<?=$data->rotate?>" data-screenoff="<?=$data->screenoff?>" data-zoom="<?=$data->zoom?>" <?=$data->localbrowser?>>
			<div class="switchlabel" for="localbrowser"></div>
			<i id="setting-localbrowser" class="setting fa fa-gear <?=( $data->localbrowser === 'checked' ? '' : 'hide' )?>"></i>
			<span class="help-block hide"><wh>Chromium</wh> - Browser on RPi connected screen. Overscan change needs a reboot.</span>
		</div>
		<div class="col-l gr">File sharing<i class="fa fa-network fa-lg wh"></i></div>
		<div class="col-r">
			<input id="samba" type="checkbox" data-usb="<?=$data->readonlyusb?>" data-sd="<?=$data->readonlysd?>" <?=$data->samba?>>
			<div class="switchlabel" for="samba"></div>
			<i id="setting-samba" class="setting fa fa-gear <?=( $data->samba === 'checked' ? '' : 'hide' )?>"></i>
			<span class="help-block hide"><wh>Samba</wh> - Share your files in USB drives and SD card on your network.</span>
		</div>
		<div class="col-l gr">Password login<i class="fa fa-lock fa-lg wh"></i></div>
		<div class="col-r">
			<input id="password" type="checkbox"<?=$passworddefault?> <?=$password?>>
			<div class="switchlabel" for="password"></div>
			<i id="setting-password" class="setting fa fa-gear <?=( $password === 'checked' ? '' : 'hide' )?>"></i>
			<span class="help-block hide">Protect the UI with a password. (Default is "rune")</span>
		</div>
		<div class="col-l gr">UPnP<i class="fa fa-upnp fa-lg wh"></i></div>
		<div class="col-r">
			<input id="upnp" type="checkbox"
				data-gmusicuser="<?=$data->gmusicuser?>"
				data-gmusicpass="<?=$data->gmusicpass?>"
				data-gmusicquality="<?=$data->gmusicquality?>"
				data-spotifyuser="<?=$data->spotifyuser?>"
				data-spotifypass="<?=$data->spotifypass?>"
				data-qobuzquality="<?=$data->qobuzquality?>"
				data-qobuzuser="<?=$data->qobuzuser?>"
				data-qobuzpass="<?=$data->qobuzpass?>"
				data-tidaluser="<?=$data->tidaluser?>"
				data-tidalpass="<?=$data->tidalpass?>"
				data-tidalquality="<?=$data->tidalquality?>"
				data-ownqueuenot="<?=$data->ownqueuenot?>"
			<?=$data->upnp?>>
			<div class="switchlabel" for="upnp"></div>
			<i id="setting-upnp" class="setting fa fa-gear <?=( $data->upnp === 'checked' ? '' : 'hide' )?>"></i>
			<span class="help-block hide"><wh>upmpdcli</wh> - Receive audio streaming via UPnP / DLNA.</span>
		</div>
	<div style="clear: both"></div>
</div>
