$( function() { // document ready start >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

var dirsystem = '/srv/http/data/system';
var formdata = {}
mountStatus();

var html = heredoc( function() { /*
	<form id="formmount">
		<div id="infoRadio" class="infocontent infohtml">
			Type&emsp;<label><input type="radio" name="protocol" value="cifs"> CIFS</label>&emsp;
			<label><input type="radio" name="protocol" value="nfs"> NFS</label>
		</div>
		<div id="infoText" class="infocontent">
			<div id="infotextlabel">
				&emsp;&emsp;&emsp;&emsp;&emsp;Name<br>
				IP<br>
				<span id="sharename">Share name</span><br>
				<span class="guest">
					User<br>
					Password<br>
				</span>
				Options
			</div>
			<div id="infotextbox">
				<input type="text" class="infoinput" name="name" spellcheck="false">
				<input type="text" class="infoinput" name="ip" spellcheck="false">
				<input type="text" class="infoinput" name="directory" spellcheck="false">
				<div class="guest">
				<input type="text" class="infoinput" name="user" spellcheck="false">
				<input type="password" class="infoinput" name="password">
				</div>
				<input type="text" class="infoinput" name="options" spellcheck="false">
			</div>
		</div>
	</form>
*/ } );
$( '#addnas' ).click( function() {
	infoMount();
} );
$( '#infoContent' ).on( 'click', '#infoRadio', function() {
	if ( $( this ).find( 'input:checked' ).val() === 'nfs' ) {
		$( '#sharename' ).text( 'Share path' );
		$( '.guest, #infoRadio1' ).addClass( 'hide' );
	} else {
		$( '#sharename' ).text( 'Share name' );
		$( '.guest, #infoRadio1' ).removeClass( 'hide' );
	}
} );
$( '#list' ).on( 'click', 'li', function( e ) {
	var mountpoint = $( this ).data( 'mountpoint' );
	var mountname = mountpoint.replace( / /g, '\\040' );
	var device = $( this ).data( 'device' );
	var nas = mountpoint.slice( 9, 12 ) === 'NAS';
	if ( $( e.target ).hasClass( 'remove' ) ) {  // remove
		info( {
			  icon    : 'network'
			, title   : 'Remove Network Mount'
			, message : '<wh>'+ mountpoint +'</wh>'
					   +'<br><br>Continue?'
			, oklabel : '<i class="fa fa-minus-circle"></i>Remove'
			, okcolor : '#bb2828'
			, ok      : function() {
				local = 1;
				$.post( 'commands.php', { bash: [
						  "sed -i '\\|"+ mountname +"| d' /etc/fstab"
						, 'rmdir "'+ mountpoint +'" &> /dev/null'
						, 'rm -f "'+ dirsystem +'/fstab-'+ mountname.split( '/' ).pop() +'"'
						, pstream( 'sources' )
					] }, function() {
					mountStatus();
					resetlocal();
				} );
			}
		} );
		return
	}
	
	if ( !$( this ).data( 'unmounted' ) ) { // unmount
		if ( $( this ).find( 'gr' ).text() === '/dev/sda1' ) {
			info( {
				  icon    : 'usbdrive'
				, title   : 'System data drive'
				, message : '<wh>'+ mountpoint +'</wh>'
						   +'<br>This drive contains system data.'
						   +'<br><wh>Unmount not allowed.</wh>'
			} );
			return
		}
		
		info( {
			  icon    : nas ? 'network' : 'usbdrive'
			, title   : 'Unmount '+ ( nas ? 'Network Share' : 'USB Drive' )
			, message : '<wh>'+ mountpoint +'</wh>'
					   +'<br><br>Continue?'
			, oklabel : 'Unmount'
			, okcolor : '#de810e'
			, ok      : function() {
				local = 1;
				$.post( 'commands.php', { bash: [
						  ( nas ? '' : 'udevil ' ) +'umount -l "'+ mountname +'"'
						, pstream( 'sources' )
					] }, function() {
					mountStatus();
					resetlocal();
				} );
			}
		} );
	} else { // remount
		info( {
			  icon    : nas ? 'network' : 'usbdrive'
			, title   : 'Mount '+ ( nas ? 'Network Share' : 'USB Drive' )
			, message : '<wh>'+ mountpoint +'</wh>'
					   +'<br><br>Continue?'
			, oklabel : 'Mount'
			, ok      : function() {
				local = 1;
				$.post( 'commands.php', { bash: [
						  ( nas ? 'mount "'+ mountname +'"' : 'udevil mount '+ device )
						, pstream( 'sources' )
					] }, function() {
					mountStatus();
					resetlocal();
				} );
			}
		} );
	}
} );
$( '#listshare' ).on( 'click', 'li', function() {
	if ( $( this ).find( '.fa-search' ).length ) {
		$( '#listshare' ).html( '<li><i class="fa fa-network blink"></i><grl>Scanning ...</grl></li>' );
		$.post( 'commands.php', { bash: '/srv/http/settings/sourceslookup.sh' }, function( data ) {
			if ( data.length ) {
				var htmlshare = '';
				data.forEach( function( el ) {
					var val = el.split( '^^' );
					var host = val[ 0 ];
					var ip = val[ 1 ];
					var share = val[ 2 ];
					htmlshare += '<li data-mount="//'+ ip +'/'+ share +'"><i class="fa fa-network"></i><gr>'+ host +'&ensp;&raquo;&ensp;</gr>//'+ ip +'/'+ share +'</li>';
				} );
			} else {
				var htmlshare = '<li><i class="fa fa-search"></i><grl>No shares available.</grl></li>';
			}
			$( '#listshare' ).html( htmlshare );
		}, 'json' );
	} else {
		var source = $( this ).data( 'mount' );
		var ipshare = source.split( '/' );
		var share = ipshare.pop();
		var ip = ipshare.pop();
		infoMount( {
			  protocol  : 'cifs'
			, name      : share
			, ip        : ip
			, directory : share
		}, 'cifs' );
	}
} );

function mountStatus() {
	$.post( 'commands.php', { bash: '/srv/http/settings/sourcestatus.sh' }, function( data ) {
		if ( !data ) return
		
		var htmlnas = '';
		var htmlusb = '';
		var htmlunmount = '';
		data.forEach( function( el ) {
			var mountpoint = el.split( ' ' )[ 0 ].replace( /\/$/, '' );
			if ( el.slice( 9, 12 ) === 'USB' ) {
				htmlusb += '<li data-mountpoint="'+ mountpoint +'"><i class="fa fa-usbdrive"></i>'+ el +'</li>';
			} else if ( el.slice( 9, 12 ) === 'NAS' ) {
				htmlnas += '<li data-mountpoint="'+ mountpoint +'"><i class="fa fa-network"></i>'+ el +'</li>';
			} else {
				var devmount = el.split( '^^' );
				var device = devmount[ 0 ];
				if ( device.slice( 0, 4 ) === '/dev' ) {
					var icon = 'usbdrive';
					var removemount = '';
				} else {
					var icon = 'network';
					var removemount = '<i class="fa fa-minus-circle remove"></i></li>';
				}
				var mountpoint = devmount[ 1 ].replace( /\/$/, '' );
				htmlunmount += '<li data-mountpoint="'+ mountpoint +'" data-device="'+ device +'" data-unmounted="1"><i class="fa fa-'+ icon +'"></i><gr>'
							  + mountpoint +'</gr><a class="red">&ensp;&bull;&ensp;</a>'+ device + removemount;
			}
		} );
		$( '#list' ).html( htmlusb + htmlnas + htmlunmount );
	}, 'json' );
}
function infoMount( formdata, cifs ) {
	info( {
		  icon    : 'network'
		, title   : 'Mount Share'
		, content : html
		, preshow : function() {
			if ( $.isEmptyObject( formdata ) ) {
				$( '#infoRadio input' ).eq( 0 ).prop( 'checked', 1 );
				$( '#infotextbox input:eq( 1 )' ).val( '192.168.1.' );
			} else {
				$( '#infoRadio input' ).eq( formdata.protocol === 'cifs' ? 0 : 1 ).prop( 'checked', 1 );
				$( '#infotextbox input:eq( 0 )' ).val( formdata.name );
				$( '#infotextbox input:eq( 1 )' ).val( formdata.ip );
				$( '#infotextbox input:eq( 2 )' ).val( formdata.directory );
				$( '#infotextbox input:eq( 3 )' ).val( formdata.user );
				$( '#infotextbox input:eq( 4 )' ).val( formdata.password );
				$( '#infotextbox input:eq( 5 )' ).val( formdata.options );
			}
			if ( cifs ) $( '#infoRadio' ).hide();
		}
		, ok      : function() {
			var formmount = $( '#formmount' ).serializeArray();
			var data = {};
			$.map( formmount, function( val ) {
				data[ val[ 'name' ] ] = val[ 'value' ];
			});
			var mountpoint = '/mnt/MPD/NAS/'+ data.name;
			var ip = data.ip;
			var directory = data.directory.replace( /^\//, '' );
			if ( data.protocol === 'cifs' ) {
				var options = 'noauto';
				options += ( !data.user ) ? ',username=guest' : ',username='+ data.user +',password='+ data.password;
				options += ',uid='+ $( '#list' ).data( 'uid' ) +',gid='+ $( '#list' ).data( 'gid' ) +',iocharset=utf8';
				options += data.options ? ','+ data.options : '';
				var device = '"//'+ ip +'/'+ directory +'"';
			} else {
				var options = 'defaults,noauto,bg,soft,timeo=5';
				options += data.options ? ','+ data.options : '';
				var device = '"'+ ip +':/'+ directory +'"';
			}
			var cmd = '"'+ mountpoint +'" '+ ip +' '+ device +' '+ data.protocol +' '+ options;
			local = 1;
			$.post( 'commands.php', { bash: [
					  '/srv/http/settings/sourcesmount.sh '+ cmd
					, pstream( 'sources' )
				] }, function( std ) {
				var std = std[ 0 ];
				if ( std ) {
					formdata = data;
					info( {
						  icon    : 'network'
						, title   : 'Mount Share'
						, message : std
						, ok      : function() {
							infoMount( formdata );
						}
					} );
				} else {
					mountStatus();
					formdata = {}
				}
				resetlocal();
			}, 'json' );
		}
	} );
}

} ); // document ready end <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
