<?php
if ( file_exists( '/usr/bin/hostapd' ) ) { ?>
	$hostapd = exec( "$sudo/systemctl is-active hostapd" ) === 'active' ? 1 : 0;
	$ssid = exec( "$sudo/grep ssid= /etc/hostapd/hostapd.conf | cut -d= -f2" );
	$passphrase = exec( "$sudo/grep '^wpa_passphrase' /etc/hostapd/hostapd.conf | cut -d'=' -f2" );
	$ipwebuiap = exec( "$sudo/grep 'router' /etc/dnsmasq.conf | cut -d',' -f2" );
}
?>
<div class="container">
	<div id="divinterface">
		<headingnoline>Interfaces&emsp;<i id="refreshing" class="fa fa-wifi-3 blink hide"></i></headingnoline>
		<ul id="listinterfaces" class="entries"></ul>
		<span class="help-block hide">Use LAN if available or select Wi-Fi to connect a network.<br><br></span>
	</div>
	<div id="divwifi" class="hide">
		<headingnoline>Wi-Fi&emsp;
			<i id="add" class="fa fa-plus-circle"></i>&ensp;<i id="scanning" class="fa fa-wifi-3 blink"></i>
			<i id="back" class="fa fa-arrow-left"></i>
		</headingnoline>
		<ul id="listwifi" class="entries"></ul>
		<span class="help-block hide">Access points with less than -66dBm should not be used.</span>
	</div>
	<div id="divwebui" class="hide">
		<div class="col-l">Web UI</div>
		<div class="col-r">
			<gr>http://</gr><span id="ipwebui"></span><br>
			<div class="divqr">
				<div id="qrwebui" class="qr"></div>
			</div>
			<span class="help-block hide">Scan QR code or use IP address to connect RuneAudio web user interface.</span>
		</div>
	</div>
<?php if ( isset( $hostapd ) ) { ?>
	<div id="divaccesspoint">
		<heading>RPi access point</heading>
		<div class="col-l">Enable</div>
		<div class="col-r">
			<input id="accesspoint" type="checkbox" data-passphrase="<?=$passphrase?>" data-ip="<?=$ipwebuiap?>" <?=( $hostapd ? 'checked' : '' )?>>
			<div class="switchlabel" for="accesspoint"></div>
			<i id="settings-accesspoint" class="setting fa fa-gear <?=( $hostapd ? '' : 'hide' )?>"></i>
			<span class="help-block hide">RPi access point should be used only when LAN or Wi-Fi were not available.</span>
		</div>
		<p class="brhalf"></p>
		<div id="boxqr" class="hide">
			<div class="col-l">Credential</div>
			<div class="col-r">
				<gr>SSID:</gr> <span id="ssid"><?=$ssid ?></span><br>
				<gr>Password:</gr> <span id="passphrase"><?=( $passphrase ?: '(No password)' )?></span>
				<div class="divqr">
					<div id="qraccesspoint" class="qr"></div>
				</div>
				<span class="help-block hide">Scan QR code or find the SSID and use the password to connect remote devices with RPi access point.</span>
			</div>
			<div class="col-l">Web UI</div>
			<div class="col-r">
				<gr>http://</gr><span id="ipwebuiap"><?=$ipwebuiap ?></span>
				<div class="divqr">
					<div id="qrwebuiap" class="qr"></div>
				</div>
				<span class="help-block hide">Scan QR code or use the IP address to connect RuneAudio web user interface with any browsers from remote devices.</span>
			</div>
		</div>
	</div>
<?php } ?>
	<div style="clear: both"></div>
</div>
