package sensing
{
	import flash.events.DataEvent;
	import flash.events.Event;
	import flash.events.*;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	//import flash.net.XMLSocket;
	//import flash.net.Socket;
	import flash.net.*;
	
	import mx.controls.Alert;
	import mx.controls.Button;
	
    

	
	
	public class arduinoSensor extends EventDispatcher
	{
		public static const DATA_CHANGED:String = 'data_changed_event';
	
		protected var _data:Array = new Array();
		
		protected var _socketName:String;
		protected var _socketPort:Number;
		public var _socket:Socket;

		
		[Bindable(event=DATA_CHANGED)]
		public function get getData():Object{
			return _data[0];	
			
		}
		
		
		
		public function get data():Array{
			return _data;
		}
		
		public function arduinoSensor(socket:String,port:Number)
		{
			_socketName = socket;
			_socketPort = port;

			_socket = new Socket();
			_socket.addEventListener(Event.CONNECT,onConnect);
			_socket.addEventListener(Event.CLOSE,onDisconnect);
			//_socket.addEventListener(DataEvent.DATA,updateData);
			_socket.addEventListener(IOErrorEvent.IO_ERROR, handleSocketEvent);
			_socket.addEventListener(SecurityErrorEvent.SECURITY_ERROR, handleSocketEvent);
			_socket.addEventListener(ProgressEvent.SOCKET_DATA, socketDataHandler);

			_socket.connect(_socketName,_socketPort);
			
		}

    protected function socketDataHandler(event:ProgressEvent):void
    {
	// Get the value from the potentiometer (0-1024) and
	// normalize it to (0-2) range for the fire component.
	//Alert.show("here");
	var value:String = String(_socket.readUTFBytes(_socket.bytesAvailable));
	//value = value/512;
	_data[0]=value;
	this.dispatchEvent(new Event(DATA_CHANGED));
	
    
    }


	protected function onConnect(e:Event):void{
		Alert.show("** Arduino connected! **");
		
	}
	
	protected function handleSocketEvent(e:Event):void{
			Alert.show("Event:" + e.toString() + 
				"\nTarget:" + e.currentTarget.toString() );
		}
	
		//this gets triggered when Flash disconnects from Arduino
	protected function onDisconnect(e:Event):void{
		Alert.show("** Arduino disconnected! **");
	}
	
	protected function updateData(de:DataEvent):void{
			if(de.data){
				_data.unshift(processData(de.data));
				this.dispatchEvent(new Event(DATA_CHANGED));
				
			}
			
		}
	
	protected function processData(d:String):Object{
			return d;
		}


	}
}