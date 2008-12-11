package sqlite
{
	import flash.events.DataEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.XMLSocket;
	
	import mx.controls.Alert;
	
	public class SQLiteHandler extends EventDispatcher
	{
		private var TABLE_NAME:String = "Mobile_Reading";
		private var BAD_METER_DEGREE_CONVERSION:Number = 1/111000;
		
		
		protected var _socketName:String;
		protected var _socketPort:Number;
		public var _socket:XMLSocket;
		
		public function SQLiteHandler(socket:String,port:Number){
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
		
		protected function updateData(de:DataEvent):void{
			if(de.data){
				//TODO: May need to do some additional processing here before returning it
				this.dispatchEvent(de);
			}
		}
		
		protected function handleSocketEvent(e:Event):void{
			Alert.show("Event:" + e.toString() + 
				"\nTarget:" + e.currentTarget.toString() );
		}
		
		/**
		 * Send a string to the socket 
		 * @param s
		 * 
		 */		
		public function sendData(s:String):void{
			if(_socket.connected) _socket.send(s);
			else Alert.show("Socket not connected");
		}
		
		/**
		 * Send a sqlite INSERT query containing the entire tuple 
		 * @param data
		 * @param onComplete
		 * 
		 */		
		public function sendTuple(data:Object):void{
			var sqlString:String = "1,INSERT INTO " + TABLE_NAME + " ";
			var cols:String = "";
			var vals:String = ""; 
			for (var k:String in data){
				cols += (k + ",");
				if(k == "datetime") vals += (data[k].toString() + ",");
				else vals += (data[k].valueOf() + ",");
			}
			if(cols.length > 0) cols = cols.substr(0,cols.length - 1);
			if(vals.length > 0) vals = vals.substr(0,vals.length - 1);
			cols = ("("+cols+")");
			vals = ("("+vals+")");
			
			sqlString += (cols + " VALUES " + vals);
			
			sendData(sqlString);
		}
		
			
		public function getTuples(latitude:Number, longitude:Number,
			startDate:Date, endDate:Date, resource="energy",distanceMeters:Number=100):void{
			var distanceDegrees:Number = distanceMeters * BAD_METER_DEGREE_CONVERSION; 
			var sqlString:String = "0,SELECT * FROM " + TABLE_NAME + " WHERE resource = " + resource + " AND "
				"latitude BETWEEN " + (latitude - distanceDegrees) + " AND " + (latitude + distanceDegrees) + " AND " + 
				"longitude BETWEEN " + (longitude - distanceDegrees) + " AND " + (longitude + distanceDegrees) + " AND " +
				"datetime BETWEEN " + startDate.valueOf() + " AND " + endDate.valueOf();
			
			sendData(sqlString); 
		}
	}
}