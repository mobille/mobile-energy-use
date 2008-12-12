package sensing
{
	import flash.events.DataEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.XMLSocket;
	
	import mx.controls.Alert;
	import mx.controls.Button;
	
	public class Sensor extends EventDispatcher
	{
		public static const DATA_CHANGED:String = 'data_changed_event';
	
		protected var _data:Array = new Array();
		
		protected var _socketName:String;
		protected var _socketPort:Number;
		public var _socket:XMLSocket;

		
		[Bindable(event=DATA_CHANGED)]
		public function get currentData():Object{
			return _data[0];	
		}
		
		public function get data():Array{
			return _data;
		}
		
		/**
		 * Constructor 
		 * @param socket
		 * @param port
		 * 
		 */		
		public function Sensor(socket:String,port:Number)
		{
			_socketName = socket;
			_socketPort = port;

			_socket = new XMLSocket();
			_socket.addEventListener(DataEvent.DATA,updateData);
			_socket.addEventListener(Event.CONNECT, handleSocketEvent);
			_socket.addEventListener(Event.CLOSE, handleSocketEvent);
			_socket.addEventListener(IOErrorEvent.IO_ERROR, handleSocketEvent);
			_socket.addEventListener(SecurityErrorEvent.SECURITY_ERROR, handleSocketEvent);
			_socket.connect(_socketName,_socketPort);	
		}
		
		protected function handleSocketEvent(e:Event):void{
			Alert.show("Event:" + e.toString() + 
				"\nTarget:" + e.currentTarget.toString() );
		}
		
		/**
		 * Event handler called when data is recieved on the socket 
		 * @param de
		 * 
		 */		
		protected function updateData(de:DataEvent):void{
			if(de.data){
				_data.unshift(processData(de.data));
				this.dispatchEvent(new Event(DATA_CHANGED));
			}
		}
		
		
		public function sendData(s:String):void{
			if(_socket.connected){ 
				_socket.send(s);
				//Alert.show("Message (\"" + s + "\") sent to " + _socketName + ":" + _socketPort);
			}
			else Alert.show("Socket not connected");
		}
		
		/**
		 * Performs additional data processing on the recieved string.
		 * (To be overridden in subclasses.) 
		 * @param d
		 * @return 
		 * 
		 */		
		protected function processData(d:String):Object{
			return d;
		}
	}
}