package sqlite
{
	import flare.data.converters.JSONConverter;
	import flare.util.Strings;
	
	import flash.events.DataEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.XMLSocket;
	
	import mx.controls.Alert;
	
	public class SQLiteHandler extends EventDispatcher
	{
		private var DEFAULT_SOCKET:String = "127.0.0.1";
		private var DEFAULT_PORT:int = 6000;
		private var TABLE_NAME:String = "Mobile_Reading";
		private var RESPONSE_LIMIT:int = 200;
		
		
		protected var _socketName:String;
		protected var _socketPort:Number;
		public var _socket:XMLSocket;
		
		//The most recent data returned
		protected var _data:Array;
		public function get data():Array { return _data;}

		protected static const _instance:SQLiteHandler = new SQLiteHandler(SQLHSingletonLock);
		public static function get instance():SQLiteHandler{return _instance;} 
		
		public function SQLiteHandler(lock:Class){
			super();
			if(lock != SQLHSingletonLock){
				throw new Error("SQLiteHandler is a singleton. Use SQLiteHandler.instance in lieu of SQLiteHandler()");
			}
			_socketName = DEFAULT_SOCKET;
			_socketPort = DEFAULT_PORT;

			_socket = new XMLSocket();
			_socket.addEventListener(DataEvent.DATA,updateData);
			_socket.addEventListener(Event.CONNECT, handleSocketEvent);
			_socket.addEventListener(Event.CLOSE, handleSocketEvent);
			_socket.addEventListener(IOErrorEvent.IO_ERROR, handleSocketEvent);
			_socket.addEventListener(SecurityErrorEvent.SECURITY_ERROR, handleSocketEvent);
			_socket.connect(_socketName,_socketPort);
		}
		
		
		
		protected function updateData(de:DataEvent):void{
			Alert.show("Event:" + de.toString() + 
				"\nTarget:" + de.currentTarget.toString());
			
			if(de.data){
				try{
					var jc:JSONConverter = new JSONConverter();
					var tempData:Array = jc.parse(de.data,null);
					_data = new Array();	
						
					//clean up data and make names consistent with web database 
					
					for each(var d:Object in tempData){
						var nd:Object = new Object();
						for (var dx:String in d){
							if(dx == 'date') nd[dx]= Strings.format("{0:s}",new Date(d[dx])).replace("T"," ").replace(/-/g,"/");
							else{
								if(dx == 'value') nd['rate']=int(d[dx]as Number);
								if(dx == 'deviceId') nd['name']='Mobile Device '+d[dx];
								nd[dx]=d[dx];
							}
						}	
						_data.push(nd);
					}
					
					
					Alert.show("Data Parsed: (" + _data.length + ")"+ 
						"\nTarget:" + de.data.toString());			
					this.dispatchEvent(de);
				}
				catch(e:Error){
					Alert.show("Error in/near JSON conversion: (" + e.name + e.message + ")");
				}
			}
		}
		
		protected function handleSocketEvent(e:Event):void{
			Alert.show("Event:" + e.toString() + 
				"\nTarget:" + e.currentTarget.toString());
		}
		
		/**
		 * Send a string to the socket 
		 * @param s
		 * 
		 */		
		public function sendData(s:String):void{
			if(_socket.connected){
				_socket.send(s);
			} 
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
				if(k == "date") vals += (data[k].valueOf() + ",");
				else if (data[k] is String) vals += ("'" + data[k] +"',");
				else vals += (data[k].valueOf() + ",");
			}
			if(cols.length > 0) cols += "randomKey"
			if(vals.length > 0) vals += int(Math.random()*100000);
			cols = ("("+cols+")");
			vals = ("("+vals+")");
			
			sqlString += (cols + " VALUES " + vals);
			//Alert.show("calling send method with string:" + sqlString);
			sendData(sqlString);
		}
			
		public function getTuples(latitude:Number, longitude:Number,
			startDate:Date, endDate:Date, resource:String=null,distanceMeters:Number=100):void{
			var distanceDegrees:Number = distanceMeters * MobileEnergyUse.METERS_TO_DEGREES_BAD_CONVERSION; 
			var sqlString:String = "0,SELECT * FROM " + TABLE_NAME + " WHERE " + (resource?"sensorName = '" + resource + "' AND ":"") +
				"latitude BETWEEN " + (latitude - distanceDegrees) + " AND " + (latitude + distanceDegrees) + " AND " + 
				"longitude BETWEEN " + (longitude - distanceDegrees) + " AND " + (longitude + distanceDegrees) + " AND " +
				"date BETWEEN " + startDate.valueOf() + " AND " + endDate.valueOf() +
				" ORDER BY randomKey LIMIT " + RESPONSE_LIMIT;
			
			sendData(sqlString); 
		}
	}
}

//A Private class accessible only to SQLiteHandler - prevents outside instantiation.
class SQLHSingletonLock
{
}